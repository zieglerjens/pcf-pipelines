#!/bin/bash
set -e

if [[ -n ${OPSMAN_CLIENT_ID} ]]; then
  CREDS="--client-id ${OPSMAN_CLIENT_ID} --client-secret ${OPSMAN_CLIENT_SECRET}"
else
  CREDS="--username ${pcf_opsman_admin_username} --password ${pcf_opsman_admin_password}"
fi

om-linux \
  --target "https://opsman.${pcf_ert_domain}" \
  --skip-ssl-validation \
  configure-authentication \
  ${CREDS} \
  --decryption-passphrase "$pcf_opsman_admin_password"
