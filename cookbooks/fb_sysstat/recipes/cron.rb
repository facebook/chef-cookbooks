# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_sysstat
# Recipe:: cron
#
# Copyright (c) 2013-present, Facebook, Inc.
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

case node['platform_family']
when 'rhel', 'fedora', 'suse'
  sa_dir = '/usr/lib64/sa'
else
  fail "fb_sysstat: not supported on #{node['platform_family']}, aborting!"
end

{
  'sysstat_accounting_1' => {
    'time' => '*/10 * * * *',
    'command' => "#{sa_dir}/sa1 -S DISK,SNMP 1 1 &> /dev/null",
    'oncall' => 'oncall+oscore@xmail.facebook.com',
  },
  'sysstat_accounting_2' => {
    'time' => '53 23 * * *',
    'command' => "#{sa_dir}/sa2 -A &> /dev/null",
    'oncall' => 'oncall+oscore@xmail.facebook.com',
  },
}.each do |k, v|
  node.default['fb_cron']['jobs'][k] = v
end

# the sa[12] commands here trample on those defined in the
# sysstat_accounting_[12] jobs
file '/etc/cron.d/sysstat' do
  action :delete
end
