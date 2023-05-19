#!/usr/bin/env bash

before_test() {
  echo "before_test" > /dev/null
}

do_test() {
  local testcase="test-0"
  for url in "1.1.2.1" "1.1.1.1" "https://google.com/" "https://rickandmortyapi.com/api"
  do
    @do_curl_local ${url}
    @do_curl_remote ${url}
  done
}

after_test() {
  echo "after_test" > /dev/null
}

before_test
do_test
after_test
