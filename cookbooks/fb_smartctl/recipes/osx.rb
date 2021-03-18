#
# Cookbook Name:: fb_osquery
# Recipe:: osx
#
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
#

package 'smartmontools' do
  action :upgrade
end

smartctl_path = '/opt/homebrew/bin/smartctl'
execute 'enable smartctl' do
  only_if do
    # So far this holds for OSX but the disk will probably be an attribute later
    s = Mixlib::ShellOut.new("#{smartctl_path} -a disk0")
    s.run_command
    s.stdout[/SMART support is:\s+(Enabled|Disabled)/, 1] == 'Disabled'
  end
  command "#{smartctl_path} -s on disk0"
end
