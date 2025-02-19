#!/bin/bash
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2022-present, Vicarious, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A script to help downstream users keep cookbooks in sync

set -u

# Constants
CONFIG_FILE_NAME='sync_fb_cookbooks.conf'
DEFAULT_UPSTREAMDIR="$HOME/src/chef-cookbooks"
DEFAULT_INTERNALDIR="$HOME/src/chef"
STATIC_CONFIG_OPTIONS=(
  "$HOME/.config/$CONFIG_FILE_NAME"
  "/etc/$CONFIG_FILE_NAME"
)

# Globals
mode=''
cookbook=''
config=''
debug=0
dryrun=0

inside_git() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

determine_config() {
  # if we're inside a git repo..
  if inside_git; then
    debug "Inside git repo..."
    # then find the root
    root=$(git rev-parse --show-toplevel)
    attempt="${root}/.${CONFIG_FILE_NAME}"
    if [ -r "${attempt}" ]; then
      debug "Using $attempt"
      echo "$attempt"
      return
    fi
  fi
  for attempt in "${STATIC_CONFIG_OPTIONS[@]}"; do
    debug "checking $attempt"
    if [ -r "$attempt" ]; then
      echo "$attempt"
      return
    fi
  done
}

debug() {
  if [ "$debug" -eq 0 ]; then
    return
  fi
  echo "DEBUG: $*" >&2
}

error() {
  echo "ERROR: $*"
}

warn() {
  echo "WARNING: $*"
}

info() {
  echo "INFO: $*"
}

die() {
  error "$@"
  exit 1
}

ourhelp() {
  cat <<EOF
Usage: $0 [<options>]

OPTIONS
    -c <cookbook>
        Compare just <cookbook>

    -C <config_file>
        Path to config file

    -d
        Diff mode

    -D
        Enable debug

    -h
        This

    -i <dir>
        Where your clone of the INTERNAL repo is
        Default: $DEFAULT_INTERNALDIR

    -n
        Run rsync in dryrun mode
    -p
        Push changes internal -> upstream

    -s
        Sync changes upstream -> internal

    -u <dir>
        Where your clone of the UPSTREAM repo is
        Default: $DEFAULT_INTERNALDIR

    -x
        Exit after printing config

CONFIG FILE
You can also tell this script where your repos are by creating config
in shell format and defining 'upstreamdir' and 'internaldir', like so:

    upstreamdir="\$HOME/mycheckouts/chef-cookbooks"
    internaldir="\$HOME/mycheckouts/chef"

$0 will look for config files in the following places, and use the first
one it finds:

  - \$REPO_ROOT/.sync_fb_cookbooks.conf  # note the dot
  - ~/.config/sync_fb_cookbooks.conf
  - /etc/sync_fb_cookbooks.conf

Where \$REPO_ROOT is the toplevel of your git repo.

CONFIGURATION VIA ENVIRONMENT VARIABLE
You can pass upstreamdir and internaldir via environment variables
as well.

GENERAL USAGE
    # get a list of cookbooks that differ
    $ $0
    ...
    fb_sysfs does not match
    ...

    # Get a diff for a specific cookbook
    $ $0 -c fb_sysfs
    ...

    # Pull in upstream changes
    $ $0 -c fb_sysfs -s
    ...

    # OR.... push out internal changes
    $ $0 -c fb_sysfs -p
EOF
}

# loads config in default -> configfile -> environment -> cli order
load_config() {
  # save what was passed in either through env vars, if they exist,
  # that should win over config file
  # or command-line...
  env_internaldir=""
  env_upstreamdir=""
  # +x syntax required to not trip up -u
  if [[ -n "${internaldir+x}" ]]; then
    env_internaldir="$internaldir"
  fi
  if [[ -n "${upstreamdir+x}" ]]; then
    env_upstreamdir="$upstreamdir"
  fi

  # initialize with defaults
  internaldir="$DEFAULT_INTERNALDIR"
  upstreamdir="$DEFAULT_UPSTREAMDIR"

  # if a configuration file was not passed in on the command line,
  # walk our possible config paths...
  if [ -z "$config" ]; then
    config=$(determine_config)
  fi

  # if we have a config, load it...
  if [ -n "$config" ]; then
    info "Loading config from $config"
    # shellcheck disable=SC1090
    source "$config" || die "Configuration file $config malformed"
  fi

  # env/cli (cli wins)
  if [ -n "$cli_internaldir" ]; then
    internaldir="$cli_internaldir"
  elif [ -n "$env_internaldir" ]; then
    internaldir="$env_internaldir"
  fi

  if [ -n "$cli_upstreamdir" ]; then
    upstreamdir="$cli_upstreamdir"
  elif [ -n "$env_upstreamdir" ]; then
    upstreamdir="$env_upstreamdir"
  fi
}

cli_internaldir=''
cli_upstreamdir=''
while getopts 'c:C:dDhi:npsu:x' opt; do
  case $opt in
    c)
      cookbook="$OPTARG"
      ;;
    C)
      config="$OPTARG"
      ;;
    d)
      mode='diff'
      ;;
    D)
      debug=1
      ;;
    h)
      ourhelp
      exit
      ;;
    i)
      cli_internaldir="$OPTARG"
      ;;
    n)
      dryrun=1
      ;;
    p)
      mode='push'
      ;;
    s)
      mode='sync'
      ;;
    u)
      cli_upstreamdir="$OPTARG"
      ;;
    x)
      mode='dumpconfig'
      ;;
    ?)
      ourhelp
      exit 1
      ;;
  esac
done

load_config

info "Using upstreamdir: $upstreamdir | internaldir: $internaldir"

if [[ $mode == 'dumpconfig' ]]; then
  exit
fi

if [ -z "$mode" ]; then
  if [ -n "$cookbook" ]; then
    mode='diff'
  else
    mode='status'
  fi
fi

rsyncargs="-avz"
if [ "$dryrun" -eq 1 ];then
  rsyncargs="${rsyncargs}n"
fi

cd "$internaldir/cookbooks" || die "where am I?"
[ -z "$cookbook" ] && cookbook="$(ls -d fb_*)"
for cb in $cookbook; do
  ours="$cb/"
  upstream="$upstreamdir/cookbooks/$cb/"
  if [ "$cb" = 'fb_init' ]; then
    upstream="$upstreamdir/cookbooks/fb_init_sample/"
  fi
  if [ "$mode" = 'status' ]; then
    diff -Nru "$ours" "$upstream" &>/dev/null || echo "$cb does not match"
  elif [ "$mode" = 'diff' ]; then
    diff -Nru "$ours" "$upstream"
  elif [ "$mode" = 'push' ]; then
    rsync "$rsyncargs" "$ours" "$upstream"
  elif [ "$mode" = 'sync' ]; then
    rsync "$rsyncargs" "$upstream" "$ours"
  else
    die "wut? wut mode is '$mode'"
  fi
done
