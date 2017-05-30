#!/bin/bash
set -e

echo "=============================================================================================="
echo "Deploying Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

if [[ -n ${OPSMAN_CLIENT_ID} ]]; then
  CREDS="--client-id ${OPSMAN_CLIENT_ID} --client-secret ${OPSMAN_CLIENT_SECRET}"
else
  CREDS="--username ${pcf_opsman_admin} --password ${pcf_opsman_admin_passwd}"
fi

# Apply Changes in Opsman

om-linux --target https://opsman.$pcf_ert_domain -k \
       ${CREDS} \
  apply-changes
