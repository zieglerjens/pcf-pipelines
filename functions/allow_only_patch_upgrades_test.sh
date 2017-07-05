#!/bin/bash
set -u

function TestAllowOnlyPatchUpgradesShouldFailIfNotAPatchUpgrade () (
  # fake the om-linux command
  function om-linux () {
    echo "+----------------+------------------+
    |      NAME      |     VERSION      |
    +----------------+------------------+
    | acme-product-1 | 1.11.0-build.100 |
    | acme-product-2 | 1.8.0            |
    +----------------+------------------+
    "    
  }
 
  # fake the ls command
  function ls () {
    echo "blah-1.13.yml manifest.yml blah.html"
  }

  if ! (allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./"); then
    return ${SUCCESS}
  fi
  return ${FAILURE}
)

function TestAllowOnlyPatchUpgradesShouldAllowAPatchUpgrade () (
  function om-linux () {
    echo "+----------------+------------------+
    |      NAME      |     VERSION      |
    +----------------+------------------+
    | acme-product-1 | 1.13.0-build.100 |
    | acme-product-2 | 1.8.0            |
    +----------------+------------------+
    "    
  }

  function ls () {
    echo "blah-1.13.yml manifest.yml blah.html"
  }
  
  if allow_only_patch_upgrades "a" "b" "c" "acme-product-1" "./"; then
    return ${SUCCESS}
  fi
  return ${FAILURE}
)

function TestAllowOnlyPatchUpgradesShouldFilterOnExactProductName () (
  function om-linux () {
    echo "+----------------+------------------+
    |      NAME      |     VERSION      |
    +----------------+------------------+
    | acme-product-1 | 1.13.0-build.100 |
    | acme-product-2 | 1.8.0            |
    +----------------+------------------+
    "    
  }

  function ls () {
    echo "blah-1.13.yml manifest.yml blah.html"
  }

  if allow_only_patch_upgrades "a" "b" "c" "acme-product" "./"; then
    echo "no product name exact match, but function did not fail"
    return ${FAILURE}
  fi
  return ${SUCCESS}
)
