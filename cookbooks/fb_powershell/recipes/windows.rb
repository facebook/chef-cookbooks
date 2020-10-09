#
# Cookbook Name:: fb_powershell
# Recipe:: windows
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

# Manage the Package

# Windows will has WindowsPowershell plus it can also run Pwsh 6+ (open source)

# Windows Powershell
# Upgrade to latest package if no specific version given
chocolatey_package 'upgrade windows powershell' do
  package_name 'powershell'
  only_if { node['fb_powershell']['powershell']['manage'] }
  only_if { node['fb_powershell']['powershell']['version'].nil? }
  action :upgrade
end

# Only install specific version, if given
chocolatey_package 'pin windows powershell' do
  package_name 'powershell'
  only_if { node['fb_powershell']['powershell']['manage'] }
  not_if { node['fb_powershell']['powershell']['version'].nil? }
  action :install
  version lazy { node['fb_powershell']['powershell']['version'] }
end

# Install PowerShell (pwsh) aka powershell-core
# Upgrade to latest package if no specific version given
chocolatey_package 'upgrade powershell-core' do
  package_name 'powershell-core'
  only_if { node['fb_powershell']['pwsh']['manage'] }
  only_if { node['fb_powershell']['pwsh']['version'].nil? }
  action :upgrade
end

# Only install specific version, if given
chocolatey_package 'pin powershell-core' do
  package_name 'powershell-core'
  only_if { node['fb_powershell']['pwsh']['manage'] }
  not_if { node['fb_powershell']['pwsh']['version'].nil? }
  action :install
  version lazy { node['fb_powershell']['pwsh']['version'] }
end

# Setup PowerShell-Config folder
# Use PathHelper since the ENV returns "C:\\" and this breaks with Dir.glob
core_path = Chef::Util::PathHelper.escape_glob_dir(
  File.join(ENV['ProgramFiles'], 'PowerShell'),
)
glob = Dir.glob(core_path + '/[6789]*')
glob .each do |install|
  path = File.join(install, 'powershell.config.json')
  template path do # ~FB031
    only_if { node['fb_powershell']['manage_config'] }
    source 'powershell.config.json.erb'
    rights :full_control, ['Administrators', 'SYSTEM']
    rights :read, 'Users'
    action :create
  end
end
