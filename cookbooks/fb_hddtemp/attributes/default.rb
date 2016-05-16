# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

if node.debian? || node.ubuntu?
  sysconfig = {
    'run_daemon' => false,
    'disks' => '',
    'disks_noprobe' => '',
    'interface' => '127.0.0.1',
    'port' => 7634,
    'database' => '/etc/hddtemp.db',
    'separator' => '|',
    'run_syslog' => 0,
    'options' => '',
  }
elsif node.centos?
  sysconfig = {
    'hddtemp_options' => '-l 127.0.0.1',
  }
else
  sysconfig = {}
end

default['fb_hddtemp'] = {
  'enable' => false,
  'sysconfig' => sysconfig,
}
