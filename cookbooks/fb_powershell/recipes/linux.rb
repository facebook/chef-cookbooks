#
# Cookbook Name:: fb_powershell
# Recipe:: linux
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

# Upgrade to latest package if no specific version given
package 'upgrade powershell' do
  package_name 'powershell'
  only_if { node['fb_powershell']['pwsh']['manage'] }
  only_if { node['fb_powershell']['pwsh']['version'].nil? }
  action :upgrade
end

# Only install specific version, if given
package 'pin powershell' do
  package_name 'powershell'
  only_if { node['fb_powershell']['pwsh']['manage'] }
  not_if { node['fb_powershell']['pwsh']['version'].nil? }
  action :install
  version lazy { node['fb_powershell']['pwsh']['version'] }
end

# Setup PowerShell-Config folder
FB::PowerShell.install_pwsh_path_list.each do |install|
  path = File.join(install, 'powershell.config.json')
  template path do # ~FB031
    only_if { node['fb_powershell']['manage_config'] }
    source 'powershell.config.json.erb'
    owner node.root_user
    group node.root_group
    mode '0744'
    action :create
  end
end

# Manage PowerShell Core profiles
fb_powershell_apply_profiles 'Managing PowerShell profiles' do
  powershell_core true
end
