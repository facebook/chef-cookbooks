#
# Cookbook Name:: fb_rpm
# Recipe:: default
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.centos?
  fail 'fb_rpm is only supported on CentOS!'
end

include_recipe 'fb_rpm::packages'
