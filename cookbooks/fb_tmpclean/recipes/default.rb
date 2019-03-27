#
# Cookbook Name:: fb_tmpwatch
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

include_recipe 'fb_tmpclean::packages'

case node['platform_family']
when 'rhel', 'fedora'
  config = '/etc/cron.daily/tmpwatch'
  config_src = 'tmpwatch.erb'
when 'debian'
  config = '/etc/cron.daily/tmpreaper'
  config_src = 'tmpreaper.erb'
when 'mac_os_x'
  config = '/usr/bin/fb_tmpreaper'
  config_src = 'tmpreaper.erb'
else
  fail "Unsupported platform_family #{node['platform_family']}, cannot" +
    'continue'
end

template config do
  source config_src
  mode '0755'
  owner 'root'
  group 'root'
end

if node.macosx?
  launchd 'com.facebook.tmpreaper' do
    action :enable
    program config
    start_calendar_interval(
      'Hour' => 2,
      'Minute' => 2,
    )
  end
end
