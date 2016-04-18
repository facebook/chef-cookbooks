#
# Cookbook Name:: fb_swap
# Recipe:: default
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

if node.systemd?
  swap_mounts = node['filesystem2']['by_device'].to_hash.select do |_k, v|
    v['fs_type'] == 'swap'
  end

  swap_unit = nil
  case swap_mounts.count
  when 0
    Chef::Log.debug('No swap mounts found, nothing to do here.')
  when 1
    swap_device = swap_mounts.keys[0].split('/')[2]
    swap_unit = "dev-#{swap_device}.swap"
    Chef::Log.debug("Found swap device: #{swap_device}")
  else
    fail 'More than one swap mount found, this is not right.'
  end

  if swap_unit
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
end

execute 'turn_swap_on' do
  only_if do
    node['memory']['swap']['total'] == '0kB' &&
    node['fb_swap']['enabled']
  end
  command '/sbin/swapon -a'
end

execute 'turn_swap_off' do
  only_if do
    node['memory']['swap']['total'] != '0kB' &&
    !node['fb_swap']['enabled']
  end
  command '/sbin/swapoff -a'
end
