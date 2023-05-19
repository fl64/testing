#!/usr/bin/env bash

do_test() {
  local testcase="test-2"
  for url in "1.1.2.1" "1.1.1.1" "https://google.com/" "https://rickandmortyapi.com/api"
  do
    @do_curl_local ${url}
    @do_curl_remote ${url}
  done
}

do_test
