# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_dcrpm
# Recipe:: default
#
# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved - Do Not Redistribute
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

include_recipe 'fb_dcrpm::packages'

node.default['fb_logrotate']['configs']['dcpm'] = {
  'files' => [
    '/var/log/dcrpm.log',
  ],
}

cmd = '/usr/bin/dcrpm --check-stuck-yum --verbose'
if node.centos7?
  cmd += ' --clean-yum-transactions'
end

node.default['fb_timers']['jobs']['dcrpm'] = {
  'only_if' => proc { node['fb_dcrpm']['enable_periodic_task'] },
  'calendar' => FB::Systemd::Calendar.every(1).hours,
  'command' => cmd,
  'accuracy' => '1s',
  'splay' => '30',
}
