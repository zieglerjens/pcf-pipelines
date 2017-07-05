#!/bin/bash
set -u

if [[ $# != 1 ]]; then
  echo "usage: $0 <path-to-files>"
  exit 1
fi

SRCDIR=$1
source "${SRCDIR}"/allow_only_patch_upgrades.sh

function TestWhenVersionsAreAllowedIsNotGivenAnyArgumentsItFails () {
  if ! ( versions_are_allowed ); then
    echo "we should have failed b/c the correct number of arguments was not given"
    return 1
  fi
  return 0
}

function TestVersionsAreAllowedShouldSucceedWithValidUpgradeVersions () {
  if ! ( versions_are_allowed "blah-1.11.yml" "1.11" ); then
    echo "we should not error if there is a valid upgrade path"
    return 1
  fi

  return 0
}

function TestVersionsAreAllowedShouldFaileWithInValidUpgradeVersions () {
  if versions_are_allowed "blah-1.11.yml" "1.10"; then
    echo "we should fail on a minor version upgrade"
    return 1
  fi

  return 0
}

function TestVersionsAreAllowedShouldSucceedWithSpacesInVersionValues () {
  if ! ( versions_are_allowed "blah-1.11.yml" " 1.11" ); then
    echo "we should be properly filtering spaces on version matchers"
    return 1
  fi

  return 0
}

function TestVersionsAreAllowedShouldSucceedMultipleProductFiles () {
  if ! ( versions_are_allowed "blah-1.11.yml manifest.yml blah.html" "1.11" ); then
    echo "we should not error if there is a valid upgrade path"
    return 1
  fi

  return 0
}


function TestVersionsAreAllowedShouldFailWhenAttemptingNonPatchUpgrades () {
  if versions_are_allowed "blah-1.11.yml manifest.yml blah.html" "1.10"; then
    echo "we should fail on a minor version upgrade"
    return 1
  fi

  return 0
}


function TestFilterDeployedProductVersionsCanFilterOMOutput () {
  deployed_products_fixture="+----------------+------------------+
  |      NAME      |     VERSION      |
  +----------------+------------------+
  | acme-product-1 | 1.13.0-build.100 |
  | acme-product-2 | 1.8.0            |
  +----------------+------------------+
  "
  res=$(filter_deployed_product_versions "${deployed_products_fixture}" "acme-product-1")
  if [[ "${res}" != "1.13" ]] ; then
    echo "we should have parsed the proper major/minor version from the product data"
    echo "${res} doesnt match 1.13"
    return 1
  fi

  return 0
}

function TestFilterDeployedProductVersionsFiltersOnExactProductNameOnly () {
  deployed_products_fixture="+----------------+------------------+
  |      NAME      |     VERSION      |
  +----------------+------------------+
  | acme-product-1 | 1.13.0-build.100 |
  | some-other-one | 1.8.0            |
  +----------------+------------------+
  "
  res=$(filter_deployed_product_versions "${deployed_products_fixture}" "product")
  if [[ "${res}" == "1.13" ]] ; then
    echo "we should have parsed on exact product name matches only"
    echo "${res} doesnt match 1.13"
    return 1
  fi

  return 0
}
