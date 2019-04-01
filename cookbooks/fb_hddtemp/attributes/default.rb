# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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
