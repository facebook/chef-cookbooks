#!/bin/bash
# OS X doesn't support cron.d directories. It also doesn't have a stock
# /etc/crontab -- so we fake it here.

set -e

# OS X also doesn't have a "tempfile" command...
tempfile="/tmp/cron.d.$$"

cat /etc/cron.d/* > "$tempfile"

if ! diff "$tempfile" "/etc/crontab" > /dev/null 2> /dev/null
then
  echo "Installing new /etc/crontab"
  mv -f "$tempfile" /etc/crontab
else
  rm -f "$tempfile"
fi

