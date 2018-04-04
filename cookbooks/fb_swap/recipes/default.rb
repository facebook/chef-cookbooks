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

base_swap_device = FB::FbSwap.get_base_swap_device(node)

unless base_swap_device
  Chef::Log.debug('fb_swap: No swap mounts found, nothing to do here.')
  return
end

Chef::Log.debug("fb_swap: Found swap device: #{base_swap_device}")

fstab_swap_uuid = FB::FbSwap.get_swap_uuid_from_fstab(node)

if fstab_swap_uuid.nil? && node['fb_swap']['enable_encryption']
  # TODO(yangxia): Fix this (t20145202).
  Chef::Log.warn(
    'fb_swap: Encryption cannot be enabled for machines where /etc/fstab ' +
    'does not specify the UUID of the swap device. Proceeding without ' +
    'encrypting swap.',
  )
end

if node.systemd?
  template '/etc/crypttab' do
    only_if do
      node['fb_swap']['enabled'] &&
      node['fb_swap']['enable_encryption'] &&
      !fstab_swap_uuid.nil?
    end
    source 'crypttab.erb'
    owner 'root'
    group 'root'
    mode '600'
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
    if node.centos?
      notifies :run, 'execute[rebuild all initramfs]'
    end
  end

  # setup / teardown encrypted swap device
  encrypted_swap_device_unit =
    FB::Systemd.path_to_unit(FB::FbSwap::ENCRYPTED_DEVICE_NAME, 'device')
  encrypted_swap_unit =
    FB::Systemd.path_to_unit(FB::FbSwap::ENCRYPTED_DEVICE_NAME, 'swap')

  # If we don't want encrypted swap, then mask the encrypted swap and device
  # units to disable them.
  service 'mask encrypted swap' do
    only_if do
      node['fb_swap']['enabled'] && !node['fb_swap']['enable_encryption']
    end
    service_name encrypted_swap_unit
    action [:stop, :mask]
  end

  service 'mask encrypted swap device' do
    only_if do
      node['fb_swap']['enabled'] && !node['fb_swap']['enable_encryption']
    end
    service_name encrypted_swap_device_unit
    action [:stop, :mask]
    notifies :reload, 'ohai[filesystem2]', :immediately
  end

  # If we want an encrypted swap, disable the non encrypted swap unit.
  service 'mask base swap unit' do
    only_if do
      node['fb_swap']['enabled'] &&
      node['fb_swap']['enable_encryption'] &&
      !fstab_swap_uuid.nil?
    end
    service_name FB::Systemd.path_to_unit(base_swap_device, 'swap')
    action [:stop, :mask]
  end

  # If we do want encrypted swap, enable the encrypted device
  service 'start encrypted swap device' do
    only_if do
      node['fb_swap']['enabled'] &&
      node['fb_swap']['enable_encryption'] &&
      !fstab_swap_uuid.nil?
    end
    service_name encrypted_swap_device_unit
    action [:unmask, :start]
    notifies :reload, 'ohai[filesystem2]', :immediately
  end

  # Make sure the current swap's UUID is the same as the one specified in
  # /etc/fstab.
  service 'pre-mask swap unit' do
    only_if do
      node['fb_swap']['enabled'] &&
      !fstab_swap_uuid.nil? &&
      FB::FbSwap.get_current_swap_device_uuid(node) != fstab_swap_uuid
    end
    service_name lazy { FB::FbSwap.get_current_swap_unit(node) }
    action [:stop, :mask]
  end

  execute 'set UUID for swap device' do
    only_if do
      node['fb_swap']['enabled'] &&
      !fstab_swap_uuid.nil? &&
      FB::FbSwap.get_current_swap_device_uuid(node) != fstab_swap_uuid
    end
    command lazy {
      '/sbin/mkswap -U ' +
      "#{fstab_swap_uuid} #{FB::FbSwap.get_current_swap_device(node)}"
    }
  end

  # start / stop swap the right thing to enabled - either the encrypted
  # one or non-encrypted one
  service 'mask swap unit' do
    not_if { node['fb_swap']['enabled'] }
    service_name lazy { FB::FbSwap.get_current_swap_unit(node) }
    action [:stop, :mask]
  end

  service 'unmask swap unit' do
    only_if { node['fb_swap']['enabled'] }
    service_name lazy { FB::FbSwap.get_current_swap_unit(node) }
    action [:unmask, :start]
  end

  file '/etc/crypttab' do
    only_if do
      node['fb_swap']['enabled'] &&
      (!node['fb_swap']['enable_encryption'] || fstab_swap_uuid.nil?)
    end
    action :delete
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
    if node.centos?
      notifies :run, 'execute[rebuild all initramfs]'
    end
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
