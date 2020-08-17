#
# Cookbook Name:: fb_ntp
# Recipe:: macosx
#
# Copyright (c) 2012-present, Facebook, Inc.
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

# This recipe configures NTP specifically for macOS hosts.

# 10.14 doesn't ship the legacy ntpd
launchd 'disable legacy ntpd' do
  action :disable
  only_if do
    FB::Version.new(node['platform_version']) < FB::Version.new('10.14')
  end
  path '/System/Library/LaunchDaemons/org.ntp.ntpd-legacy.plist'
end

# 10.14 stopped reporting to the timed database. Until that's fixed, we will
# just run a manual sync once a day to make really really sure.
whyrun_safe_ruby_block 'ntphack setup' do
  block do
    node.default['fb_launchd']['jobs']['ntphack'] = {
      'program_arguments' => [
        '/usr/bin/sntp', '-Ss', node['fb_ntp']['servers'].first
      ],
      'start_interval' => 3600, # run every hour
      'time_out' => 600,
    }
  end
end
