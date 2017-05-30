#!/bin/bash

set -eu

echo "=============================================================================================="
echo "Configuring OpsManager @ https://opsman.$ERT_DOMAIN ..."
echo "=============================================================================================="

if [[ -n ${OPSMAN_CLIENT_ID} ]]; then
  CREDS="--client-id ${OPSMAN_CLIENT_ID} --client-secret ${OPSMAN_CLIENT_SECRET}"
else
  CREDS="--username ${OPSMAN_USER} --password ${OPSMAN_PASSWORD}"
fi

#Configure Opsman
om-linux --target https://opsman.$ERT_DOMAIN -k \
     configure-authentication \
       ${CREDS} \
       --decryption-passphrase "$OPSMAN_PASSWORD"
