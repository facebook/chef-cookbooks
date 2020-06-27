#
# Cookbook Name:: fb_tmpclean
# Recipe:: default
#
# Copyright (c) Facebook, Inc. and its affiliates.
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

include_recipe 'fb_tmpclean::packages'

case node['platform_family']
when 'rhel', 'fedora'
  config = '/etc/cron.daily/tmpwatch'
  config_src = 'tmpwatch.erb'
when 'debian'
  config = '/etc/cron.daily/tmpreaper'
  config_src = 'tmpreaper.erb'
when 'mac_os_x'
  config = '/usr/local/bin/fb_tmpreaper'
  config_src = 'tmpreaper.erb'
else
  fail "Unsupported platform_family #{node['platform_family']}, cannot" +
    'continue'
end

template config do
  source config_src
  mode '0755'
  owner node.root_user
  # https://github.com/chef/cookstyle/issues/657
  # rubocop:disable Lint/UnneededCopDisableDirective
  # rubocop:disable ChefDeprecations/NodeMethodsInsteadofAttributes
  group node.root_group
  # rubocop:enable ChefDeprecations/NodeMethodsInsteadofAttributes
  # rubocop:enable Lint/UnneededCopDisableDirective
end

if node.macos?
  # TODO T68640353 clean up once this is fully rolled out
  file '/usr/bin/fb_tmpreaper' do
    action :delete
  end

  launchd 'com.facebook.tmpreaper' do
    action :enable
    program config
    start_calendar_interval(
      'Hour' => 2,
      'Minute' => 2,
    )
  end
end
