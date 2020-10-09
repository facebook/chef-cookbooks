#
# Cookbook Name:: fb_powershell
# Recipe:: darwin
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

# Darwin == OSX

# Install Package
# This install Powershell core via homebrew. They just call it "powershell"

# Upgrade to latest package if no specific version given
homebrew_cask 'install powershell' do
  cask_name 'powershell'
  only_if { node['fb_powershell']['pwsh']['manage'] }
  action :install
end

# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos
# Setup PowerShell-Config folder
installs = Dir.glob('/usr/local/microsoft/powershell/[6789]*')
installs.each do |install|
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
