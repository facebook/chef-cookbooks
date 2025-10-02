#!/bin/bash
# Copyright (c) 2025-present, Phil Dibowitz
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates
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

DEBUG=0
PREFIX=':facebook: :cook: *_FB ATTRIBUTE-API COOKBOOKS UPDATE_* :facebook: :cook:

Welcome to the weekly report - this report includes both the primary
Facebook repo as well as other repos (requested to be part of this report)
that implement FB APIs.'

debug() {
    [ $DEBUG -eq 1 ] || return
    echo "DEBUG: $*" >&2
}

error() {
    echo "ERROR: $*" >&2
}

die() {
    error "$*"
    exit 1
}

usage() {
    cat <<EOF
Generate the weekly Chef Community Meeting report for FB-style cookbook repos.

Usage: $0 [<options>]

Options:
    -d          Enable debug output.
    -h          Print this message.    
EOF
}

while getopts dh opt; do
    case "$opt" in
        d)
            DEBUG=1
            ;;
        h)
            usage
            exit
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

cmd="../../oss-stats/bin/repo_stats"
debug "About to run $cmd"
if ! out=$($cmd); then
    die "Failed to run repo_stats: $!"
fi

debug "Generating full report"
cat <<EOF
$PREFIX

$out
EOF
