#!/bin/sh
#
# Copyright (c) Meta Platforms, Inc. and affiliates.
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
# vim: syntax=sh:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

set -u

# This script is meant to be called in dbus.service by ExecStartPost. It will
# trigger a systemd reload, unless it's the first time it runs or when current
# systemd target is active, which means systemd finished boot up procedure.

flag='/run/dbus-was-started-once'

# current systemd target
target=$(systemctl get-default)

# status of systemd target
result=$(systemctl is-active "$target")

if [ -r "$flag" ]; then
  echo 'dbus-restart-hack: reloading systemd as the flag file exists'
  sleep 1
  /usr/bin/systemctl daemon-reload
elif [ "$result" = "active" ]; then
  echo "dbus-restart-hack: reloading systemd as current target $target is active"
  sleep 1
  /usr/bin/systemctl daemon-reload
else
  echo 'dbus-restart-hack: not reloading systemd as this is the first start'
fi

touch "$flag"

exit 0
