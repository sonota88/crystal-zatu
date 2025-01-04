#!/bin/bash

set -o nounset

readonly IMAGE=crystal-sdl:1

cmd_build() {
  docker build \
    --build-arg USER=$USER \
    --build-arg GROUP=$(id -gn) \
    --progress plain \
    -t $IMAGE .
}

cmd_run() {
  local mount_param="type=bind"
  mount_param="${mount_param},source=$(pwd)"
  mount_param="${mount_param},target=/home/${USER}/work"

  docker run --rm -it --mount "$mount_param" \
    $IMAGE "$@"
}

cmd="$1"; shift
case $cmd in
  build | b* )
    cmd_build "$@"
;; run | r* )
     cmd_run "$@"
;; * )
     echo "invalid command (${cmd})" >&2
     ;;
esac
