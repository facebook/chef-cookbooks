#
# Cookbook Name:: fb_powershell
# Recipe:: default
#
# Copyright (c) 2020-present, Facebook, Inc.
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

case node['os']
when 'windows'
  include_recipe 'fb_powershell::windows'
when 'darwin'
  include_recipe 'fb_powershell::darwin'
when 'linux'
  include_recipe 'fb_powershell::linux'
else
  fail "fb_powershell: not supported on #{node['os']}"
end

# Setup PowerShell Config
fb_powershell_apply_config 'Managing the PowerShell Core config' do
  only_if { node['fb_powershell']['manage_config'] }
end

# Manage PowerShell Core profiles
fb_powershell_apply_profiles 'Managing PowerShell profiles' do
  only_if { node['fb_powershell']['manage_profiles'] }
  powershell_core true
end
