#
# Cookbook Name:: fb_rsync
# Recipe:: client
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

package 'rsync' do
  not_if { node.macosx? || node.aristaeos? } # provided by Xcode
  action :upgrade
end
