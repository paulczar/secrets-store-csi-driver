#!/bin/bash

assert_success() {
  if [[ "$status" != 0 ]]; then
    echo "expected: 0"
    echo "actual: $status"
    echo "output: $output"
    return 1
  fi
}

assert_failure() {
  if [[ "$status" == 0 ]]; then
    echo "expected: non-zero exit code"
    echo "actual: $status"
    echo "output: $output"
    return 1
  fi
}

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "expected: $1"
    echo "actual: $2"
    return 1
  fi
}

assert_not_equal() {
  if [[ "$1" == "$2" ]]; then
    echo "unexpected: $1"
    echo "actual: $2"
    return 1
  fi
}

assert_match() {
  if [[ ! "$2" =~ $1 ]]; then
    echo "expected: $1"
    echo "actual: $2"
    return 1
  fi
}

assert_not_match() {
  if [[ "$2" =~ $1 ]]; then
    echo "expected: $1"
    echo "actual: $2"
    return 1
  fi
}

wait_for_process(){
  wait_time="$1"
  sleep_time="$2"
  cmd="$3"
  while [ "$wait_time" -gt 0 ]; do
    if eval "$cmd"; then
      return 0
    else
      sleep "$sleep_time"
      wait_time=$((wait_time-sleep_time))
    fi
  done
  return 1
}

compare_owner_count() {
  secret="$1"
  namespace="$2"
  ownercount="$3"

  [[ "$(kubectl get secret ${secret} -n ${namespace} -o json | jq '.metadata.ownerReferences | length')" -eq $ownercount ]]
}

check_secret_deleted() {
  secret="$1"
  namespace="$2"

  result=$(kubectl get secret -n ${namespace} | grep "^${secret}$" | wc -l)
  [[ "$result" -eq 0 ]]
}

archive_info() {
  if [[ -z "${ARTIFACTS}" ]]; then
    return 0
  fi

  FILE_PREFIX=$(date +"%FT%H%M%S")

  # print all pod information
  kubectl get pods -A -o json > ${ARTIFACTS}/${FILE_PREFIX}-pods.json

  # print detailed pod information
  kubectl describe pods --all-namespaces > ${ARTIFACTS}/${FILE_PREFIX}-pods-describe.txt

  # print logs from the CSI Driver
  #
  # assumes driver is installed with helm into the `kube-system` namespace which
  # sets the `app` selector to `secrets-store-csi-driver`.
  #
  # Note: the yaml deployment would require `app=csi-secrets-store`
  kubectl logs -l app=secrets-store-csi-driver  --tail -1 -c secrets-store -n kube-system > ${ARTIFACTS}/${FILE_PREFIX}-csi-secrets-store-driver.logs

  # print client and server version information
  kubectl version > ${ARTIFACTS}/${FILE_PREFIX}-kubectl-version.txt

  # print generic cluster information
  kubectl cluster-info dump > ${ARTIFACTS}/${FILE_PREFIX}-cluster-info.txt
}
