#!/bin/bash

# takes 2 arguments 
# 1 the path to the target base json file
# 2 the path to the filter file to use
apply_ert_certificates () {
   json_file=$1
   filter_file=$2
   tmp_json=$(jq \
      --arg cert_pem "${pcf_ert_ssl_cert:?Need to set pcf_ert_ssl_cert}" \
      --arg private_key_pem "${pcf_ert_ssl_key:?Need to set pcf_ert_ssl_key}" \
      --arg saml_cert_pem "${saml_cert_pem:?Need to set saml_cert_pem}" \
      --arg saml_key_pem "${saml_key_pem:?Need to set saml_key_pem}" \
      --from-file ${filter_file} \
      ${json_file})
   echo "${tmp_json}" > ${json_file}
}
