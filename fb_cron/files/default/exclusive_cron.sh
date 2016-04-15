#!/bin/bash

if [ $# -lt 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Uses file locking to runs a single instance of a command "
  echo "on a host at a time. Intended to stop cron job stampedes"
  echo ""
  echo "Usage: exclusive_cron.sh <lockfile path> <command to run>"
  echo ""
  echo "NOTE: Uses flock, so lockfiles must be on local storage" 
  exit 1;
fi

LOCKFILE="${1}"
shift 1
COMMAND="$*"

if [ -e "${LOCKFILE}" ] && [ ! -f "${LOCKFILE}" ]; then
  echo "Lockfile ${LOCKFILE} exists, but is not a file"
  exit 1;
fi

function on_exit() {
  rm -f "${LOCKFILE}";
}

# FD200 is completely arbitrary
(
  if ! flock -x -w 0 200; then 
    echo "Comand '${COMMAND}' with lockfile '${LOCKFILE}' is already running"
    exit 1
  fi
  trap 'on_exit' EXIT
  eval "${COMMAND}"
) 200>"${LOCKFILE}"
