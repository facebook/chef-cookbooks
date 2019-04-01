#
# Cookbook Name:: fb_swap
# Recipe:: after_fb_fstab
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
