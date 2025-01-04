#!/bin/bash

set -o nounset
set -o errexit

in_container() {
  env | grep --quiet IN_CONTAINER
}

cmd="$1"; shift
case $cmd in
  build )
    if (in_container); then
      # crystal build --help
      shards build --error-trace --debug --warnings=all
    else
      ./docker.sh run bash run.sh build "$@"
    fi
;; * )
     echo "invalid command" >&2
     exit 1
     ;;
esac
