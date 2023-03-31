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

# constants
CONF="$HOME/.config/sync_fb_cookbooks.conf"

# defaults
upstreamdir="$HOME/src/chef-cookbooks"
internaldir="$HOME/src/chef"

# methods
error() {
    echo "ERROR: $*"
}

warn() {
    echo "WARNING: $*"
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

    -d
        Diff mode.

    -h
        This.

    -i <dir>
        Where your clone of the INTERNAL repo is.
        Default: $internaldir

    -p
        Push changes internal -> upstream

    -s
        Sync changes upstream -> internal

    -u <dir>
        Where your clone of the UPSTREAM repo is.
        Default: $internaldir

CONFIG FILE
You can also tell this script where your repos are by creating $CONF
in shell format and defining 'upstreamdir' and 'internaldir', like so:

    upstreamdir="\$HOME/mycheckouts/chef-cookbooks"
    internaldir="\$HOME/mycheckouts/chef"

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

# people put repos in different places, don't make them pass in
# -u and -i every time.
if [ -e "$CONF" ]; then
    # shellcheck disable=SC1090
    source "$CONF" || die "Configuration file $CONF malformed"
fi

mode=''
cookbook=''
while getopts c:dhi:psu: opt; do
    case $opt in
        c)
            cookbook="$OPTARG"
            ;;
        d)
            mode='diff'
            ;;
        h)
            ourhelp
            exit
            ;;
        i)
            internaldir="$OPTARG"
            ;;
        p)
            mode='push'
            ;;
        s)
            mode='sync'
            ;;
        u)
            upstreamdir="$OPTARG"
            ;;
        ?)
            ourhelp
            exit 1
            ;;
    esac
done

if [ -z "$mode" ]; then
    if [ -n "$cookbook" ]; then
        mode='diff'
    else
        mode='status'
    fi
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
        rsync -avz "$ours" "$upstream"
    elif [ "$mode" = 'sync' ]; then
        rsync -avz "$upstream" "$ours"
    else
        die "wut? wut mode is '$mode'"
    fi
done
