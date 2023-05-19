#!/usr/bin/env bash
curl_params="--silent --show-error --output /dev/null --connect-timeout 2 --max-time 2"
curl_output="%{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code}"
prober_ns="cilium-test-prober"
prober_pod="deployments/prober"

testcase="default"

capture () {
  # src https://gist.github.com/pmarreck/5eacc6482bc19b55b7c2f48b4f1db4e8
  local out_var out err_var err ret_var ret
  out_var="$1"; shift
  err_var="$1"; shift
  ret_var="$1"; shift
  . <({ err=$({ out=$("$@"); ret=$?; } 2>&1; declare -p out ret >&2); declare -p err; } 2>&1)
  read $out_var <<<$out
  read $err_var <<<$err
  read $ret_var <<<$ret
}

curl_remote() {
  kubectl -n "${prober_ns}" exec "${prober_pod}" -- bash -c "curl ${curl_params} -w \"${curl_output}\" \"${1}\""
}

curl_local() {
  curl ${curl_params} -w "${curl_output}" "${1}"
}

curl_output_wrapper() {
  capture t_stdout t_stderr t_ret "$@"
  if [[ ${t_ret} -ne 0 ]]; then
    status=🟥
  else
    echo "${t_stdout}" | grep -q "= 200"
    ret=$?
    if [[ ${ret} -ne 0 ]]; then
      status=🟨
    else
      status=🟩
    fi
  fi
  #echo $icon $t_stdout $t_stderr
  printf '{ "script": "%s", "status":"%s", "type" : "%s", "stdout":"%s", "exit_code":"%s", "stderr":"%s"}\n' "${testcase}" "${status}" "${1}" "${t_stdout}" "${t_ret}" "${t_stderr}" | jq -c .
  return "${t_ret}"
}

@do_curl_local() {
  curl_output_wrapper curl_local "${@}"
  return $?
}

@do_curl_remote() {
  curl_output_wrapper curl_remote "${@}"
  return $?
}

@test_case() {
  printf '{ "test_case": "%s" }\n' "${testcase}" | jq -c .
}

for test_case in $(find testcases/ -mindepth 1 -maxdepth 1 -type d | sort -t '\0' -n ); do
  source "${test_case}/test.sh"
done



for url in "1.1.2.1" "1.1.1.1" "https://google.com/" "https://rickandmortyapi.com/api"
do
  @do_curl_local ${url}
  @do_curl_remote ${url}
done
