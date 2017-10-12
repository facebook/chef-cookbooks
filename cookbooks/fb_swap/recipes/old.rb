#
# Cookbook Name:: fb_swap
# Recipe:: old
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

swap_mounts = node['filesystem2']['by_device'].to_hash.select do |_k, v|
  v['fs_type'] == 'swap'
end

case swap_mounts.count
when 0
  Chef::Log.debug('No swap mounts found, nothing to do here.')
  return
when 1
  swap_device = swap_mounts.keys[0]
  Chef::Log.debug("Found swap device: #{swap_device}")
else
  fail 'More than one swap mount found, this is not right.'
end

if node.systemd?
  swap_unit = FB::Systemd.path_to_unit(swap_device, 'swap')

  service 'mask swap unit' do # ~FC038
    not_if { node['fb_swap']['enabled'] }
    service_name swap_unit
    action [:stop, :mask]
  end

  service 'unmask swap unit' do # ~FC038
    only_if { node['fb_swap']['enabled'] }
    service_name swap_unit
    action [:unmask, :start]
  end
end

whyrun_safe_ruby_block 'validate swap size' do
  only_if do
    node['fb_swap']['size'] && node['fb_swap']['size'].to_i < 1024
  end
  block do
    fail 'You asked for a swap device smaller than 1 MB. This is probably ' +
         'not what you want. Please make it larger or disable swap altogether.'
  end
end

whyrun_safe_ruby_block 'validate resize' do
  only_if do
    node['fb_swap']['enabled'] && node['fb_swap']['size'] &&
    node['memory']['swap']['total'] != '0kB' &&
    (node['fb_swap']['size'].to_i - 4) > node['memory']['swap']['total'].to_i
  end
  block do
    fail 'fb_swap does not support increasing the size of a swap device'
  end
end

execute 'resize swap' do
  only_if do
    node['fb_swap']['enabled'] && node['fb_swap']['size'] &&
    # actual size is always desired - 4
    (node['fb_swap']['size'].to_i - 4) < node['memory']['swap']['total'].to_i
  end
  command lazy {
    uuid = node['filesystem2']['by_device'][swap_device]['uuid']
    size = node['fb_swap']['size']
    "swapoff #{swap_device} && mkswap -U #{uuid} #{swap_device} #{size} && " +
    "swapon #{swap_device}"
  }
end

execute 'turn swap on' do
  only_if do
    node['memory']['swap']['total'] == '0kB' &&
    node['fb_swap']['enabled']
  end
  command '/sbin/swapon -a'
end

execute 'turn swap off' do
  only_if do
    node['memory']['swap']['total'] != '0kB' &&
    !node['fb_swap']['enabled']
  end
  command '/sbin/swapoff -a'
end
