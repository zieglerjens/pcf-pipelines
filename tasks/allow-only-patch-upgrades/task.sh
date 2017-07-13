#!/bin/bash

set -eu

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "Checking if you are applying an allowed patch upgrade @ ${OPSMAN_URI}"

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
  local deployed_version_complete=$(get_deployed_product_version ${OPS_MGR_HOST} ${OPS_MGR_USR} ${OPS_MGR_PWD} ${PRODUCT_NAME})
  local new_version_complete=$(get_new_product_version $PRODUCT_DIR)
  local deployed_version_major_minor=$(format_semver_major_minor "${deployed_version_complete}")
  local new_version_major_minor=$(format_semver_major_minor ${new_version_complete})

  if [[ ${deployed_version_complete} == ${new_version_complete} ]];then
    echo "You are attempting to install a version that is already installed: ${deployed_version_complete}"
    exit 1
  fi

  if [[ ${deployed_version_major_minor} == "" ]];then
      echo "version check yielded empty version information from product call:"
      echo ${deployed_version_major_minor}
      exit 1 
  fi

  if [[ ${new_version_major_minor} == ${deployed_version_major_minor} ]]; then
    echo "we have a safe upgrade for version: ${deployed_version_major_minor}";

  else
    echo "You are trying to install version: "
    cat ${PRODUCT_DIR}/version
    echo
    echo "Your currently deployed version is: "
    echo "${deployed_version_major_minor}"
    echo
    echo "Pivotal recommends that you only automate
    patch upgrades of PCF, and perform major or minor
    upgrades manually to ensure that no high-impact
    changes to the platform are introduced without
    your prior knowledge."
    echo
    echo "To upgrade patch releases, we suggest using the following version regex in your params file:"
    echo "${deployed_version_major_minor}" | awk -F"." '{print "^"$1"\\\."$2"\\..*$"}'
    exit 1
  fi
}

function get_new_product_version () {
  local PRODUCT_DIR=$1
  local complete_new_version=$(cat ${PRODUCT_DIR}/version)
  local new_version_no_timestamp=$(format_notimestamp ${complete_new_version})
  echo ${new_version_no_timestamp// }
}

function get_deployed_product_version () {
  local OPS_MGR_HOST=$1
  local OPS_MGR_USR=$2
  local OPS_MGR_PWD=$3
  local PRODUCT_NAME=$4
  local products="$( om-linux \
    --target "https://${OPS_MGR_HOST}" \
    --username "${OPS_MGR_USR}" \
    --password "${OPS_MGR_PWD}" \
    --skip-ssl-validation \
    curl --path /api/v0/deployed/products -s )"
  local complete_version=$(echo "${products}" | jq -r --arg product "$PRODUCT_NAME" '.[] | select(.type == $product) | .product_version')
  echo "${complete_version// }"
}

function format_notimestamp () {
  echo $1 | awk -F"\#" '{print $1}'
}

function format_semver_major_minor () {
  echo $1 | awk -F"." '{print $1"."$2}'
}

allow_only_patch_upgrades ${OPSMAN_URI} ${OPSMAN_USERNAME} ${OPSMAN_PASSWORD} ${PRODUCT_NAME} ${PRODUCT_FILES_DIR}
