#
# Cookbook Name:: fb_iproute
# Recipe:: packages
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

package %w{iproute iproute-tc} do
  only_if { node['fb_iproute']['manage_packages'] }
  action :upgrade
end
