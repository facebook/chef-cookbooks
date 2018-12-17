#
# Cookbook Name:: fb_cron
# Recipe:: packages
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

case node['platform_family']
when 'rhel', 'fedora', 'suse'
  package_name = 'vixie-cron'
  if node['platform'] == 'amazon' || node['platform_version'].to_i >= 6
    package_name = 'cronie'
  end
end

if package_name # ~FC023
  package package_name do
    action :upgrade
  end
end
