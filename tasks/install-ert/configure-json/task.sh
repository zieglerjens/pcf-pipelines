#!/bin/bash

set -e

json_file_path="pcf-pipelines/tasks/install-ert/json_templates/${pcf_iaas}/${terraform_template}"
json_file_template="${json_file_path}/ert-template.json"
jq_filter_path="pcf-pipelines/jq-filters"

if [ ! -f "$json_file_template" ]; then
  echo "Error: can't find file=[${json_file_template}]"
  exit 1
fi

json_file="json_file/ert.json"

cp ${json_file_template} ${json_file}

if [[ ${pcf_ert_ssl_cert} == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for sys.${pcf_ert_domain} & cfapps.${pcf_ert_domain} ..."
  echo "=============================================================================================="
  pcf-pipelines/tasks/scripts/gen_ssl_certs.sh "sys.${pcf_ert_domain}" "cfapps.${pcf_ert_domain}"
  export pcf_ert_ssl_cert=$(cat sys.${pcf_ert_domain}.crt)
  export pcf_ert_ssl_key=$(cat sys.${pcf_ert_domain}.key)
fi

system_domain=sys.${pcf_ert_domain}
ops_mgr_host="https://opsman.$pcf_ert_domain"
domains=$(cat <<-EOF
  {"domains": ["*.${system_domain}", "*.login.${system_domain}", "*.uaa.${system_domain}"] }
EOF
)
saml_cert_response=`om-linux -t $ops_mgr_host -u $pcf_opsman_admin -p $pcf_opsman_admin_passwd -k curl -p "/api/v0/certificates/generate" -x POST -d "$domains"`
saml_cert_pem=$(echo $saml_cert_response | jq --raw-output '.certificate')
saml_key_pem=$(echo $saml_cert_response | jq --raw-output '.key')

sed -i \
  -e "s/{{pcf_az_1}}/${pcf_az_1}/g" \
  -e "s/{{pcf_az_2}}/${pcf_az_2}/g" \
  -e "s/{{pcf_az_3}}/${pcf_az_3}/g" \
  -e "s/{{pcf_ert_domain}}/${pcf_ert_domain}/g" \
  -e "s/{{terraform_prefix}}/${terraform_prefix}/g" \
  -e "s/{{mysql_monitor_recipient_email}}/${mysql_monitor_recipient_email}/g" \
  ${json_file}

if [[ ${MYSQL_BACKUPS} == "scp" ]]; then
  source ${json_filter_path}/ert-mysql-backup-scp/apply_ert_mysql_backup_s3.sh
  filter_file_path=${json_filter_path}/ert-mysql-backup-scp/properties.filter
  apply_ert_mysql_backup_scp ${json_file} ${filter_file_path}
fi

if [[ ${MYSQL_BACKUPS} == "s3" ]]; then
  source ${json_filter_path}/ert-mysql-backup-s3/apply_ert_mysql_backup_s3.sh
  filter_file_path=${json_filter_path}/ert-mysql-backup-s3/properties.filter
  apply_ert_mysql_backup_s3 ${json_file} ${filter_file_path}
fi

source ${json_filter_path}/ert-certificates/apply_ert_certificates.sh
filter_file_path=${json_filter_path}/ert-certificates/properties.filter
apply_ert_certificates ${json_file} ${filter_file_path}


cat > cert_filter <<-'EOF'
  .properties.properties.".properties.networking_point_of_entry.external_ssl.ssl_rsa_certificate".value = {
    "cert_pem": $cert_pem,
    "private_key_pem": $private_key_pem
  } |
  .properties.properties.".uaa.service_provider_key_credentials".value = {
    "cert_pem": $saml_cert_pem,
    "private_key_pem": $saml_key_pem
  }
EOF

jq \
  --arg cert_pem "$pcf_ert_ssl_cert" \
  --arg private_key_pem "$pcf_ert_ssl_key" \
  --arg saml_cert_pem "$saml_cert_pem" \
  --arg saml_key_pem "$saml_key_pem" \
  --from-file cert_filter \
  $json_file > config.json
mv config.json $json_file

db_creds=(
  db_app_usage_service_username
  db_app_usage_service_password
  db_autoscale_username
  db_autoscale_password
  db_diego_username
  db_diego_password
  db_notifications_username
  db_notifications_password
  db_routing_username
  db_routing_password
  db_uaa_username
  db_uaa_password
  db_ccdb_username
  db_ccdb_password
  db_accountdb_username
  db_accountdb_password
  db_networkpolicyserverdb_username
  db_networkpolicyserverdb_password
  db_nfsvolumedb_username
  db_nfsvolumedb_password  
)

for i in "${db_creds[@]}"
do
   eval "templateplaceholder={{${i}}}"
   eval "varname=\${$i}"
   eval "varvalue=$varname"
   echo "replacing value for ${templateplaceholder} in ${json_file} with the value of env var:${varname} "
   sed -i -e "s/$templateplaceholder/${varvalue}/g" ${json_file}
done

if [[ -e pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh ]]; then
  echo "Executing ${pcf_iaas} IaaS specific config ..."
  ./pcf-pipelines/tasks/install-ert/scripts/iaas-specific-config/${pcf_iaas}/run.sh
fi
