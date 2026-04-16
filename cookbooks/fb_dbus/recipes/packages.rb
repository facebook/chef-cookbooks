#
# Cookbook Name:: fb_dbus
# Recipe:: packages
#
# Copyright (c) 2018-present, Facebook, Inc.
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

# dbus-broker relies on the dbus packages, so we install those unconditionally
include_recipe_at_converge_time 'fb_dbus::dbus_base_packages_upgrade' do
  only_if { node['fb_dbus']['manage_packages'] }
end

# only install dbus-tools when requested
include_recipe_at_converge_time 'install dbus-tools' do
  only_if do
    node['fb_dbus']['manage_packages'] &&
      node['fb_dbus']['manage_dbus_tools']
  end
  recipe 'fb_dbus::dbus_tools_upgrade'
end

include_recipe_at_converge_time 'install dbus-broker' do
  only_if do
    node['fb_dbus']['manage_packages'] &&
      (node['fb_dbus']['implementation'] == 'dbus-broker')
  end
  recipe 'fb_dbus::dbus_broker_upgrade'
end
