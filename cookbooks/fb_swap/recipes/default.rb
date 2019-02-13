#
# Cookbook Name:: fb_swap
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

device = FB::FbSwap._device(node)

unless device
  Chef::Log.debug('fb_swap: No swap mounts found, nothing to do here.')
  return
end

Chef::Log.debug("fb_swap: Found swap device: #{device}")
# Newly provisioned hosts end up with a swap device in /etc/fstab which
# is referenced by UUID (or label, or path). We use data from ohai's
# filesystem2 plugin (which is backed by the state of the machine, not what
# is in /etc/fstab). We want to create/manage our own units with predictable
# names
#
node.default['fb_fstab']['exclude_base_swap'] = true

whyrun_safe_ruby_block 'validate swap size' do
  only_if do
    node['fb_swap']['size'] && node['fb_swap']['size'].to_i < 1024
  end
  block do
    fail 'fb_swap: You asked for a swap device smaller than 1 MB. This is ' +
         'probably not what you want. Please make it larger or disable swap ' +
         'altogether.'
  end
end

# ask fb_fstab to create the unit
node.default['fb_fstab']['mounts']['swap_device'] = {
  'mount_point' => 'swap',
  'device' => device,
  'type' => 'swap',
}

whyrun_safe_ruby_block 'validate resize' do
  only_if do
    node['fb_swap']['enabled'] && node['fb_swap']['size'] &&
    node['memory']['swap']['total'] != '0kB' &&
    (node['fb_swap']['size'].to_i - 4) > node['memory']['swap']['total'].to_i
  end
  block do
    fail 'fb_swap: We do not support increasing the size of a swap device'
  end
end

execute 'resize swap' do
  only_if do
    node['fb_swap']['enabled'] && node['fb_swap']['size'] &&
    # actual size is always desired - 4
    (node['fb_swap']['size'].to_i - 4) < node['memory']['swap']['total'].to_i
  end
  command lazy {
    uuid = node['filesystem2']['by_device'][device]['uuid']
    size = node['fb_swap']['size']
    "swapoff #{device} && mkswap -U #{uuid} #{device} " +
     "#{size} && swapon #{device}"
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
