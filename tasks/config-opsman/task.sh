#!/bin/bash

set -eu

until $(curl --output /dev/null -k --silent --head --fail https://$OPS_MGR_HOST/setup); do
    printf '.'
    sleep 5
done

if [[ -n ${OPSMAN_CLIENT_ID} ]]; then
  CREDS="--client-id ${OPSMAN_CLIENT_ID} --client-secret ${OPSMAN_CLIENT_SECRET}"
else
  CREDS="--username ${OPS_MGR_USR} --password ${OPS_MGR_PWD}"
fi

om-linux \
  --target https://$OPS_MGR_HOST \
  --skip-ssl-validation \
  configure-authentication \
  ${CREDS} \
  --decryption-passphrase $OM_DECRYPTION_PWD
