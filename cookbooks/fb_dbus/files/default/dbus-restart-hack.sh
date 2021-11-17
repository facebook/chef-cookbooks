#!/bin/sh

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
