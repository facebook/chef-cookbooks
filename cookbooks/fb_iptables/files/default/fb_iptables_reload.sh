#!/bin/bash
# shellcheck disable=SC2086,SC2018,SC2019,SC1090,SC2064,SC2124,SC2181,SC2002,SC2153,SC2046,SC2173,SC2230
#
# Copyright (c) 2016-present, Facebook, Inc.
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
#

# Simple script for chef to call to
# dump and reload custom chain rules

set -u

CONFIG='/etc/fb_iptables.conf'
TMPDIR=$(mktemp -d /tmp/fb_iptables.XXXXXXXXXXXX)
trap "rm -rf $TMPDIR &>/dev/null" exit INT TERM KILL

help_print() {
  echo "$0 [4|6] <action>"
  exit;
}

exit_error() {
  msg="$@"
  echo "ERROR: $msg"
  exit 1
}

# Walk dynamic changes for a table and dump them to temp files in, if they exist
dump_dynamic_chains() {
  local table="$1"
  local dynamic_chains="$2"
  local outfile
  local chain_regex
  echo -n "  - Stashing dynamic chains on $table: "
  for chain in $dynamic_chains; do
    echo -n "$chain  "
    "${IPTABLES_CMD}" -t "$table" -S | grep -q "\-N $chain"
    if [ $? -ne 0 ]; then
      echo '(no chain yet, nothing to stash) '
      continue
    fi
    outfile=$TMPDIR/${table}_${chain}_rules
    chain_regex="\-A $chain "
    out=$("${IPTABLES_CMD}" -t "$table" -S)
    if [ $? -ne 0 ]; then
      exit_error "Failed to stash $chain on $table"
    fi
    if [ -n "$out" ]; then
      echo "$out" | grep "$chain_regex" > "$outfile"
    fi
  done
  echo 'done.'
}

# Restore any registered chains we found and backed up
restore_dynamic_chains() {
  local table="$1"
  local dynamic_chains="$2"

  echo -n "  - Restoring dynamic chains on $table: "
  for chain in $dynamic_chains; do
    echo -n "$chain "
    local rules_file=$TMPDIR/${table}_${chain}_rules
    if [ ! -r $rules_file ]; then
      echo '(no chain to restore) '
      continue
    fi

    ${IPTABLES_CMD} -t $table -F $chain
    while read -r rule
    do
      ${IPTABLES_CMD} -t $table $rule
    done < "$rules_file"
  done
  echo 'done.'
}

reload_static_chains() {
  local table="$1"

  # NOTE: You cannot use '-t' here ... ip6tables-* choke on it... you must
  # specify --table=
  echo "  - Reloading $table"
  cat "${CONFIG_DIR}/${IPTABLES_RULES_FILE}" | ${IPTABLES_CMD}-restore --table=$table
}

reload() {
    for table in $TABLES; do
      # iptables-restore triggers loading modules, even with empty
      # rules.  Let's avoid that (t28313270).
      echo "Reloading $table..."
      cap_table=$(echo $table | tr 'a-z' 'A-Z')
      static_chains=$(eval echo \$STATIC_${cap_table}_CHAINS)
      if [ -z "$static_chains" ] && ! grep -q $table /proc/net/ip*_tables_names; then
        continue
      fi
      dynamic_chains=$(eval echo \$${cap_table}_CHAINS)
      dump_dynamic_chains $table "$dynamic_chains"
      reload_static_chains $table
      restore_dynamic_chains $table "$dynamic_chains"
  done
}

[ -r "$CONFIG" ] && . $CONFIG

# Poor mans help print
if [ "$1" == "help" ]; then
  help_print
fi

# v4 or v6
IPTABLES_CMD=ip6tables
IPTABLES_RULES_FILE="$RULES6_FILE"
if [ "$1" == "4" ]; then
  IPTABLES_CMD=iptables
  IPTABLES_RULES_FILE="$RULES_FILE"
fi
ACTION="$2"

if [ ! -x $(which "${IPTABLES_CMD}") ]; then
  echo "ERROR: No ${IPTABLES_CMD} in path bro ..."
  exit 1
fi

case "$ACTION" in
  reload)
    reload
    ;;
  *)
    help_print
    ;;
esac
