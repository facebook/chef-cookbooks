#
# Cookbook Name:: fb_smartctl
# Recipe:: osx
#
# Copyright (c) 2021-present, Facebook, Inc.
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

smartmon_version = '7.2'
smartmon_hash = 'd11fk14ygy2cfyz4xijds2w4y0bx43s3'

# Cleanup the old brew2rpm version
package 'smartmontools' do
  action :remove
end

# Install the nix2rpm version of smartmontools
package "nix2rpm-smartmontools-#{smartmon_version}-#{smartmon_hash}" do
  action :upgrade
end

smartctl_path = ::File.join(
  '/opt/facebook/nix/store',
  "#{smartmon_hash}-smartmontools-#{smartmon_version}",
  'bin',
  'smartctl',
)

# Backwards compatibility
link '/opt/homebrew/bin/smartctl' do
  to smartctl_path
end

# This is what tools SHOULD use
link '/usr/local/bin/smartctl' do
  to smartctl_path
end

# On 2014 Mac Minis, SMART has to be enabled
execute 'enable smartctl' do
  only_if { node.mac_mini_2014? }
  only_if do
    # So far this holds for OSX but the disk will probably be an attribute later
    s = Mixlib::ShellOut.new("#{smartctl_path} -a disk0")
    s.run_command
    s.stdout[/SMART support is:\s+(Enabled|Disabled)/, 1] == 'Disabled'
  end
  command "#{smartctl_path} -s on disk0"
end
