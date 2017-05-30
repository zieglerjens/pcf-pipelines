#!/bin/bash
set -e

root=$(pwd)

source "${root}/pcf-pipelines/functions/check_opsman_available.sh"

if [[ -n ${OPSMAN_CLIENT_ID} ]]; then
  CREDS="--client-id ${OPSMAN_CLIENT_ID} --client-secret ${OPSMAN_CLIENT_SECRET}"
else
  CREDS="--username ${OPSMAN_USERNAME} --password ${OPSMAN_PASSWORD}"
fi

opsman_available=$(check_opsman_available $OPSMAN_URI)
if [[ $opsman_available == "available" ]]; then
  om-linux \
    --target "https://${OPSMAN_URI}" \
    --skip-ssl-validation \
    ${CREDS} \
    delete-installation
fi
