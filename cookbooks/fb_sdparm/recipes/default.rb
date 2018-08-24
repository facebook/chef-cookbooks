#
# Cookbook Name:: fb_sdparm
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

package 'sdparm' do
  action :upgrade
end

fb_sdparm 'set sdparm options' do
  only_if { node['fb_sdparm']['enforce'] }
end
