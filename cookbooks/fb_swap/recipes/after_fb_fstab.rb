#
# Cookbook Name:: fb_swap
# Recipe:: after_fb_fstab
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
# this only works once fb_fstab has actually rendered/reloaded
# fstab and systemd-fstab-generator run

['device', 'file'].each do |type|
  next if type == 'device' && FB::FbSwap._device(node).nil?

  service "start #{type} swap" do
    only_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    service_name lazy { FB::FbSwap._swap_unit(node, type) }
    action [:start]
  end

  service "stop #{type} swap" do
    # stopping is dangerous. This is true if it's needed, and it's permitted.
    only_if { node['fb_swap']['_calculated']['swapoff_needed'] }
    not_if { node['fb_swap']['enabled'] }
    service_name lazy { FB::FbSwap._swap_unit(node, type) }
    action [:stop]
  end
end
