#!/bin/bash

set -euo pipefail

VERBOSE=false
NOOP=false

usage() { echo -e "Uage: $0 [-hvn] [-- kubectl options]\n\n  -h  Display this text\n  -v  Enable verbose output\n  -n  Only print commands, don't run them"; }

run() {
  local CMD=$1
  shift
  local ARGS=$*

  set +e
  [ "$VERBOSE" == 'true' ] || [ "$NOOP" == 'true' ] && echo "> ${CMD} ${ARGS}" 1>&2
  [ "$NOOP" != 'true' ] && eval "${CMD} ${ARGS}"
  [ "$CMD" == "cat" ] && [[ ( "$VERBOSE" == 'true' || "$NOOP" == 'true' ) ]] && eval "${CMD} ${ARGS}"
  set -e
}

set +e
ARGS=$(getopt -o :hvn -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Failed to parse options."; usage; exit 1; }
set -e
eval set -- "$ARGS"

while true; do
  case "$1" in
    -v)
      VERBOSE=true
      shift
      ;;

    -n)
      NOOP=true
      shift
      ;;

    -h)
      usage
      exit 0
      ;;

    --)
      shift;
      break
      ;;

    *)
      echo "Unknown option -${OPTARG}"
      echo
      usage
      exit 1
      ;;
  esac
done

set +e
which docker &>/dev/null || (
  echo "This script currently requires docker to be installed on your local machine, sorry."
  exit 1
)
set -e

read -rp "Enter the server name of the Synapse instance: " SERVER_NAME
read -rp "Enter the namespace for the Matrix instance: " NAMESPACE

TEMP="$(mktemp -d)"
run cd "$TEMP"

echo "Generating configuration..."
run mkdir config
run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    -e "SERVER_NAME=$SERVER_NAME" \
       ananace/matrix-synapse:0.25.1 config

run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    busybox chown "$(id -u):$(id -g)" -R /synapse
 
echo "Opening an editor against the configuration"
run vim "$TEMP/config/homeserver.yaml"

run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    busybox chown "$(id -u):$(id -g)" -R /synapse
