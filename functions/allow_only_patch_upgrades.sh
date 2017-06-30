#!/bin/bash

set -eu
# 
# Gets major/minor version for deployed product
# and compares them to the product version you are
# trying to install
# if there is any difference (not including patch)
# then we should fail
#
function allow_only_patch_upgrades {
  if [ "$#" -ne 5 ]; then
      echo "Illegal number of arguments."
      echo "usage: allow_only_patch_upgrades <opsman_uri> <opsman_user> <opsman_pass> <product_name> <product_resource_dir>"
  fi
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local PRODUCT_NAME=$4
  local PRODUCT_DIR=$5
  
  local deployed_products=$(om-linux \
      --target "https://${OPS_MGR_HOST}" \
      --username "${OPS_MGR_USR}" \
      --password "${OPS_MGR_PWD}" \
      --skip-ssl-validation \
      deployed-products)

  local deployed_version=$( filter_deployed_product_versions "${deployed_products}" "${PRODUCT_NAME}" )
  local product_list=$(ls "${PRODUCT_DIR}")

  if versions_are_allowed "${product_list}" "${deployed_version}"; then
    echo "we have a safe upgrade for version: ${deployed_version}";

  else
    echo "You are trying to install version: "
    echo "${product_list}"
    echo
    echo "Your currently deployed version is: "
    echo "$deployed_version"
    echo
    echo "Pivotal recommends that you only automate
    patch upgrades of PCF, and perform major or minor
    upgrades manually to ensure that no high-impact
    changes to the platform are introduced without
    your prior knowledge."
    echo
    echo "To upgrade patch releases, we suggest using the following version regex in your params file:"
    echo "$deployed_version" | awk -F"." '{print "^"$1"\\\."$2"\\..*$"}'
    exit 1
  fi
}

function filter_deployed_product_versions {
  if [[ $# != 2 ]]; then
    echo "sorry we expected 2 arguments: <om-linux deployed-products output> <product-name>"
    return 0 
  fi
  deployed_products=$1
  product_name=$2
  version=$(echo "${deployed_products}" | grep "${product_name}" | awk -F"|" '{print $3 }' | awk -F"." '{print $1"."$2}')
  echo ${version// }
}


function versions_are_allowed {
  if [[ $# != 2 ]]; then
    echo "sorry we expected 2 arguments: <product-dir-files-list> & <deployed_version_major_minor>"
    return 0
  fi
  
  FILE_LIST=$1
  VERSION=$2

  if echo "${FILE_LIST}" | grep "${VERSION// }"; then
    return 0
  else 
    return 1
  fi
}

