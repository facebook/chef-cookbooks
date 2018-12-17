#
# Cookbook Name:: fb_tmpwatch
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
when 'rhel'
  pkg = 'tmpwatch'
when 'debian'
  pkg = 'tmpreaper'
when 'mac_os_x'
  pkg = 'tmpreaper'
else
  fail "Unsupported platform_family #{node['platform_family']}, cannot" +
    'continue'
end

package pkg do
  action :upgrade
end
