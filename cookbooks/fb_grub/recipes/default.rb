#
# Cookbook Name:: fb_grub
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

fb_grub_packages 'install packages'

grub_base_dir = '/boot/grub'
grub2_base_dir = '/boot/grub2'
node.default['fb_grub']['_grub_config'] = "#{grub_base_dir}/grub.conf"
node.default['fb_grub']['_grub2_config'] = "#{grub2_base_dir}/grub.cfg"
node.default['fb_grub']['_vendor'] = 'undefined'
node.default['fb_grub']['_efi_vendor_dir'] = '/notdefined'
node.default['fb_grub']['_grub2_module_path'] = '/notdefined'
node.default['fb_grub']['_grub2_linux_statement'] = 'linux'
node.default['fb_grub']['_grub2_initrd_statement'] = 'initrd'

whyrun_safe_ruby_block 'initialize_grub_variables' do
  only_if { node.efi? }
  block do
    if node.centos6?
      node.default['fb_grub']['_vendor'] = 'redhat'
    elsif node.debian?
      node.default['fb_grub']['_vendor'] = 'debian'
    else
      node.default['fb_grub']['_vendor'] = 'centos'
    end

    if node['fb_grub']['version'] == 2
      unless node.centos6?
        node.default['fb_grub']['_grub2_linux_statement'] = 'linuxefi'
        node.default['fb_grub']['_grub2_initrd_statement'] = 'initrdefi'
      end
      if node.debian?
        node.default['fb_grub']['_vendor'] = 'debian'
      else
        node.default['fb_grub']['_vendor'] = 'centos'
      end
    end

    node.default['fb_grub']['_efi_vendor_dir'] =
      "/boot/efi/EFI/#{node['fb_grub']['_vendor']}"

    node.default['fb_grub']['_grub_config'] =
      "#{node['fb_grub']['_efi_vendor_dir']}/grub.conf"
    node.default['fb_grub']['_grub2_config'] =
      "#{node['fb_grub']['_efi_vendor_dir']}/grub.cfg"

    # Calculate the grub2 partition for the OS
    os_device = node.device_of_mount('/')
    m = os_device.match(/[0-9]+$/)
    fail 'fb_grub::default Cannot parse OS device!' unless m
    os_partition_grub2 = "(#{node['fb_grub']['boot_disk']},#{m[0].to_i})"

    node.default['fb_grub']['_grub2_module_path'] =
      "#{os_partition_grub2}/usr/lib/grub/#{node['kernel']['machine']}-efi"
  end
end

whyrun_safe_ruby_block 'initialize_grub_locations' do
  block do
    if Pathname.new('/boot').mountpoint?
      boot_device = node.device_of_mount('/boot')
      boot_label = node['filesystem2']['by_mountpoint']['/boot']['label']
      node.default['fb_grub']['path_prefix'] = ''
    else
      boot_device = node.device_of_mount('/')
      boot_label = node['filesystem2']['by_mountpoint']['/']['label']
      node.default['fb_grub']['path_prefix'] = '/boot'
    end

    if node['fb_grub']['use_labels']
      if node['fb_grub']['version'] < 2
        fail 'fb_grub: Booting by label requires grub2.'
      end
      # TODO: make this work with both uuid + label, like the rootfs_arg section
      node.default['fb_grub']['_root_label'] = boot_label
    else
      # udev block device partitions start at 1
      # grub disks start at 0
      m = boot_device.match(/[0-9]+$/)
      fail 'fb_grub::default Cannot parse boot device!' unless m

      grub_partition = m[0].to_i - 1
      root_device = "(#{node['fb_grub']['boot_disk']},#{grub_partition})"
      node.default['fb_grub']['root_device'] = root_device

      root_device_grub2 =
        "(#{node['fb_grub']['boot_disk']},#{grub_partition + 1})"
      node.default['fb_grub']['root_device_grub2'] = root_device_grub2
    end

    # some provisioning configurations do not properly label the root filesystem
    # Ensure grub is put down with the label matching the fs mounted at / that
    # has a valid uuid or label. This will skip over things like rootfs mounts.
    node.default['fb_grub']['rootfs_arg'] = 'LABEL=/'
    label = node['filesystem2']['by_mountpoint']['/']['label']
    uuid = node['filesystem2']['by_mountpoint']['/']['uuid']
    if label && !label.empty?
      node.default['fb_grub']['rootfs_arg'] = "LABEL=#{label}"
    elsif uuid && !uuid.empty?
      node.default['fb_grub']['rootfs_arg'] = "UUID=#{uuid}"
    end
  end
end

whyrun_safe_ruby_block 'check_root_device' do
  only_if { File.exist?(node['fb_grub']['_grub_config']) }
  block do
    File.open(node['fb_grub']['_grub_config']).each do |line|
      if !node.efi? && line.match(/^\s*root\s*/)
        # we want to assert no change in root device when not using EFI
        current_root_device = line.split[1]
        if current_root_device != root_device
          fail 'fb_grub::default Grub root device mismatch: '\
               "expected #{root_device}, found #{current_root_device}"
        end
      end
    end
  end
end

directory 'efi_vendor_dir' do
  only_if { node.efi? }
  path lazy { node['fb_grub']['_efi_vendor_dir'] }
  owner 'root'
  group 'root'
  # this is on a FAT filesystem that doesn't support proper permissions
  mode '0700'
end

# GRUB 1
directory grub_base_dir do
  only_if { node['fb_grub']['version'] == 1 }
  owner 'root'
  group 'root'
  mode '0755'
end

template 'grub_config' do
  only_if do
    node['platform_family'] == 'rhel' && node['fb_grub']['kernels'] &&
      node['fb_grub']['version'] == 1
  end
  path lazy { node['fb_grub']['_grub_config'] }
  source 'grub.conf.erb'
  owner 'root'
  group 'root'
  mode node.efi? ? '0700' : '0644'
end

template 'Additional grub.conf' do
  # We need the same config in /boot/efi/... AND /boot/grub if it's EFI,
  # because grub sometimes gets installed on hd0,1 which is /boot
  only_if do
    node.efi? && node['platform_family'] == 'rhel' &&
      node['fb_grub']['kernels'] && node['fb_grub']['version'] == 1
  end
  path '/boot/grub/grub.conf'
  source 'grub.conf.erb'
  owner 'root'
  group 'root'
  mode node.efi? ? '0700' : '0644'
end

# GRUB 2
directory grub2_base_dir do
  only_if { node['fb_grub']['version'] == 2 }
  owner 'root'
  group 'root'
  mode '0755'
end

template 'grub2_config' do
  only_if do
    node['platform_family'] == 'rhel' && node['fb_grub']['kernels'] &&
      node['fb_grub']['version'] == 2
  end
  path lazy { node['fb_grub']['_grub2_config'] }
  source 'grub2.cfg.erb'
  owner 'root'
  group 'root'
  mode node.efi? ? '0700' : '0644'
end

# cleanup configs for the grub that we're not using
file 'cleanup grub_config' do
  not_if { node['fb_grub']['version'] == 1 }
  path lazy { node['fb_grub']['_grub_config'] }
  action :delete
end

directory "cleanup #{grub_base_dir}" do
  not_if { node['fb_grub']['version'] == 1 }
  path grub_base_dir
  action :delete
  recursive true
end

file 'cleanup grub2_config' do
  not_if { node['fb_grub']['version'] == 2 }
  path lazy { node['fb_grub']['_grub2_config'] }
  action :delete
end

directory "cleanup #{grub2_base_dir}" do
  not_if { node['fb_grub']['version'] == 2 }
  path grub2_base_dir
  action :delete
  recursive true
end

link '/etc/grub.conf' do
  to lazy {
    if node['fb_grub']['version'] == 2
      node['fb_grub']['_grub2_config']
    else
      node['fb_grub']['_grub_config']
    end
  }
end
