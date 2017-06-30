#!/bin/bash

set -u

function setred {
   printf '\033[1;31m'
}

function setgreen {
   printf '\033[40;38;5;82m'
}

function setdefault {
   printf '\033[0m\n'
}

if [[ $# != 1 ]]; then
   echo "usage: $0 <path-to-tests>"
   exit 1
fi

TEST_DIR=$1

TESTFILES=$(find "${TEST_DIR}" -name "*_test.sh")
EXITCODE=0
for test in ${TESTFILES}; do
   echo "running tests in: ${test}"
   ${test} "${TEST_DIR}"
   code=$?
   if [[ ${code} != 0 ]]; then
      EXITCODE=${code}
      setred 
      echo "(test failed !!!!! )"
      setdefault 
   else 
      setgreen 
      echo "(test passed)"
      setdefault 
   fi
done
exit ${EXITCODE}

