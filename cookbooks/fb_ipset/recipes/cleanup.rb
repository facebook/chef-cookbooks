#
# Cookbook Name:: fb_ipset
# Recipe:: cleanup
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

fb_ipset 'fb_ipset_auto_cleanup' do
  only_if { node['fb_ipset']['enable'] }
  action :cleanup
end
