#!/bin/bash

set -eu
set -o pipefail

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

overwrite=""
dir="${root}/.."

while getopts v:w: option; do
 case "${option}" in
 v)
    version=${OPTARG};;
 w)
    overwrite=${OPTARG:-"false"};;
 d)
    dir=${OPTARG};;
 esac
done

if [[ $(fly -h 2>&1 | grep fmt -c) ]]; then
  has_fly_fmt=0
else
  has_fly_fmt=1
fi

echo "Will pin pcf-pipelines to ${version}"

test_for_pcf_pipelines_git=$(cat <<-EOF
- op: test
  path: /resources/name=pcf-pipelines
  value:
    name: pcf-pipelines
    type: git
    source:
      uri: git@github.com:pivotal-cf/pcf-pipelines.git
      branch: master
      private_key: {{git_private_key}}
EOF
)

pin_pcf_pipelines=$(cat <<-EOF
- op: add
  path: /get=pcf-pipelines/version
  value:
    ref: ${version}
EOF
)

files=$(
  find \
    $dir \
    -type f \
    -name pipeline.yml |
  grep -v ci
)

for f in ${files[@]}; do
  if [[ $( cat $f | yaml-patch -o <(echo "$test_for_pcf_pipelines_git") 2>/dev/null ) ]]; then
    echo "Pinning ${f}"
    cat $f | yaml-patch -o <(echo "$pin_pcf_pipelines") > "${f}.pinned"

    if [[ "${overwrite}" == "true" ]]; then
      filename=$f
    else
      filename=${f/.yml/}-pinned.yml
    fi

    mv "${f}.pinned" $filename

    if [[ $has_fly_fmt == 0 ]]; then
      fly fmt --write --config $filename
    fi
  else
    echo "Skipping $f"
  fi
done
