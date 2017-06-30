#!/bin/bash
set -u

if [[ $# != 1 ]]; then
  echo "usage: $0 <path-to-files>"
  exit 1
fi

SRCDIR=$1
source "${SRCDIR}"/allow_only_patch_upgrades.sh

# given function is not given valid args
if ! ( versions_are_allowed ); then
  echo "we should have failed b/c the correct number of arguments was not given"
  exit 1
fi

# given function is given valid upgrade path args 
if ! ( versions_are_allowed "blah-1.11.yml" "1.11" ); then
  echo "we should not error if there is a valid upgrade path"
  exit 1
fi

# given function is given INvalid upgrade path args 
if versions_are_allowed "blah-1.11.yml" "1.10"; then
  echo "we should fail on a minor version upgrade"
  exit 1
fi

# given function is argument for version contains spaces 
if ! ( versions_are_allowed "blah-1.11.yml" " 1.11" ); then
  echo "we should be properly filtering spaces on version matchers"
  exit 1
fi

# given function is given valid upgrade path args (multiple file list set) 
if ! ( versions_are_allowed "blah-1.11.yml manifest.yml blah.html" "1.11" ); then
  echo "we should not error if there is a valid upgrade path"
  exit 1
fi

# given function is given INvalid upgrade path args (multiple file list set)
if versions_are_allowed "blah-1.11.yml manifest.yml blah.html" "1.10"; then
  echo "we should fail on a minor version upgrade"
  exit 1
fi

# given valid response from om-linux for deploye-products
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
  exit 1
fi
