#
# Cookbook Name:: fb_ipset
# Recipe:: default_packages
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

pkgs = ['ipset']
unless node.centos6?
  pkgs << 'ipset-service'
end

package pkgs do
  only_if { node['fb_ipset']['manage_packages'] }
  action :upgrade
end
