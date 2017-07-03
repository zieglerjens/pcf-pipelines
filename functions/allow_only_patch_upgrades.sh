#!/bin/bash

set -eu

function allow_only_patch_upgrades {
  if [ "$#" -ne 5 ]; then
      echo "Illegal number of arguments."
      echo "usage: allow_only_patch_upgrades <opsman_uri> <opsman_user> <opsman_pass> <product_name> <new_version>"
  fi
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local PRODUCT_NAME=$4
  local NEW_VERSION=$5

  local deployed_version=$(
    om-linux \
      --target "https://${OPS_MGR_HOST}" \
      --username "${OPS_MGR_USR}" \
      --password "${OPS_MGR_PWD}" \
      --skip-ssl-validation \
      curl \
      -path /api/v0/deployed/products 2>/dev/null |
    jq \
      --arg product_name "$PRODUCT_NAME" \
      --raw-output \
      '.[]
        | select(.type == $product_name)
        | .product_version
      '
  )

  if [[ -z "$deployed_version" ]]; then
    echo Could not discover deployed version of $PRODUCT_NAME.
    exit 1
  fi

  new_major_minor=$(echo "$NEW_VERSION" | jq --raw-input 'match("^([0-9]+)\\.([0-9]+)").string')
  existing_major_minor=$(echo "$deployed_version" | jq --raw-input 'match("^([0-9]+)\\.([0-9]+)").string')

  if [[ "$new_major_minor" != "$existing_major_minor" ]]; then
    echo You are trying to upgrade $PRODUCT_NAME from $deployed_version to $NEW_VERSION.
    echo
    echo "Pivotal recommends that you only automate patch upgrades of PCF, and perform major or minor upgrades manually to ensure that no high-impact changes to the platform are introduced without your prior knowledge."
    echo
    echo "To only upgrade patch releases of $PRODUCT_NAME, we suggest using the following version regex in your params file:"
    echo "$deployed_version" | awk -F"." '{print "^"$1"\\\."$2"\\..*$"}'
  fi
}
