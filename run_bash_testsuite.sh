#!/bin/bash

set -u

function setred {
   printf '\033[1;31m'
}

function setgreen {
   printf '\033[40;38;5;82m'
}

function setdefault {
   printf '\033[0m'
}

# path to tests is the root directory to
# start a recursive search for test files
if [[ $# != 1 ]]; then
   echo "usage: $0 <path-to-tests>"
   exit 1
fi

# search for convention
# test files should have suffix '_test'
TEST_DIR=$1
TESTFILES=$(find "${TEST_DIR}" -name "*_test.sh")
EXITCODE=0
SUCCESS=0
FAILURE=1


# using the convention of each test file should have a 
# function file excluding '_test' suffix
for test in ${TESTFILES}; do
   source ${test//_test.sh/.sh}
   source ${test}
done

# convention for function names is
# functions with prefix 'Test' will be executed
# and the output will pass/fail the pipeline
for testFunc in $(typeset -f | grep '^Test.*()' | awk '{print $1}'); do
   if eval "${testFunc} >> test.out"; then
      setgreen 
      printf "."
      setdefault 
   else
      EXITCODE=1
      setred 
      echo "(test failed !!!!! )"
      echo ${testFunc}
      cat test.out
      echo 
      echo "----------------------------------------------------"
      echo
      setdefault 
   fi
   rm test.out
done

if [[ ${EXITCODE} == 0 ]];then
   setgreen
   echo
   echo "TESTS PASSED"
   setdefault
else 
   setred
   echo 
   echo "TESTS FAILED"
   setdefault
fi
exit ${EXITCODE}
