#
# Cookbook Name:: test_services
# Recipe:: default
#
# Copyright (c) 2019-present, Facebook, Inc.
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

include_recipe 'fb_sasl'
include_recipe 'fb_bind'
unless node.el_min_version?(10)
  include_recipe 'fb_dhcprelay'
end
node.default['fb_dhcprelay']['sysconfig']['servers'] = ['10.1.1.1']
include_recipe 'fb_kea'
# Getting a working config for these would be pretty tricky, so for now
# we disable all 4 services, but at least let the cookbook get loaded which
# will ensure some basic sanity
%w{dhcp4 dhcp6 ddns control-agent}.each do |svc|
  node.default['fb_kea']["enable_#{svc}"] = false
end

# Currently fb_vsftpd is broken on debian
# https://github.com/facebook/chef-cookbooks/issues/149
unless node.debian?
  include_recipe 'fb_vsftpd'
end

include_recipe 'fb_apache'
if node.debian? || (node.ubuntu? && !node.ubuntu16?)
  include_recipe 'fb_apt_cacher'
  # ubuntu post-18 doesn't package echoping which the config
  # in fb_smokeping depends on, so don't run it, for now
  if node.ubuntu18? || node.ubuntu20?
    include_recipe 'fb_smokeping'
  end
  # ejabberd has issues restarting while running in Test Kitchen
  # if running behind a NAT, so don't run while using VirtualBox
  # https://github.com/openspace42/aenigma/issues/48
  # https://github.com/test-kitchen/test-kitchen/issues/458
  unless kitchen? || node['virtualization']['system'] == 'vbox'
    node.default['fb_ejabberd']['config']['hosts'] << 'sample.com'
    include_recipe 'fb_ejabberd'
  end
  include_recipe 'fb_influxdb'
end

include_recipe 'fb_spamassassin'

# Currently fb_reprepro is broken
# https://github.com/facebook/chef-cookbooks/issues/78
# include_recipe 'fb_reprepro'

# Test JSON recipes
if node.json_recipes_supported?
  include_recipe '::test_json_recipe'
end
