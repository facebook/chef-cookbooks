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

fb_grub_packages 'manage GRUB packages' do
  only_if { node['fb_grub']['manage_packages'] }
  notifies :run, 'execute[grub-install]'
end

grub_base_dir = '/boot/grub'
grub2_base_dir = '/boot/grub2'

whyrun_safe_ruby_block 'initialize_grub_locations' do
  block do
    bootdisk_guess = 'hd0'

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

      # For tboot, we have to specify the full path to the modules.
      # They are in /usr/lib/grub , so we need the label for the root disk
      slash_label = node['filesystem2']['by_mountpoint']['/']['label']
      if slash_label
        node.default['fb_grub']['_module_label'] = slash_label
      end
    else
      # If nothing has set the root_device so far, fall back to the old logic
      # and set it by using the hardcoded boot_disk parameter
      unless node['fb_grub']['root_device']
        # This is the old, somewhat broken logic to use a hardcoded root
        # udev block device partitions start at 1
        # grub disks start at 0
        m = boot_device.match(/[0-9]+$/)
        fail 'fb_grub::default Cannot parse boot device!' unless m
        grub_partition = m[0].to_i
        grub_partition -= 1 if node['fb_grub']['version'] < 2
        # In case somebody has set an override, just take whatever they set
        # otherwise just use the default and hope for the best.
        boot_disk = node['fb_grub']['boot_disk'] || bootdisk_guess
        root_device = "#{boot_disk},#{grub_partition}"
        Chef::Log.info("Using old root device logic: #{root_device}")
        node.default['fb_grub']['root_device'] = root_device
      end
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
    # Set the correct grub module path for e.g. the tboot modules
    if node.efi? && node['fb_grub']['version'] == 2 &&
       node['fb_grub']['tboot']['enable']
      if node['fb_grub']['_module_label']
        module_path = "/usr/lib/grub/#{node['kernel']['machine']}-efi"
      else
        os_device = node.device_of_mount('/')
        m = os_device.match(/[0-9]+$/)
        fail 'fb_grub::default Cannot parse OS device!' unless m
        # People can override the boot_disk if they have a good reason.
        if node['fb_grub']['boot_disk']
          boot_disk = node['fb_grub']['boot_disk']
        elsif node['fb_grub']['root_device']
          boot_disk = node['fb_grub']['root_device'].split(',')[0]
        else
          # This basically just happens if someone enables labels
          # but doesn't override the boot_disk param and we don't use our new
          # logic to figure out the boot disk
          boot_disk = bootdisk_guess
        end
        os_part = "(#{boot_disk},#{m[0].to_i})"
        module_path = "#{os_part}/usr/lib/grub/#{node['kernel']['machine']}-efi"
      end
      node.default['fb_grub']['_grub2_module_path'] = module_path
    end
    node.default['fb_grub']['_decided_boot_disk'] = boot_disk
  end
end

execute 'grub-install' do
  # https://fedoraproject.org/wiki/GRUB_2 specifically says :
  # 'grub2-install shouldn't be used on EFI systems'.  See T21894396
  not_if { node.efi? }
  command lazy {
    cmd = value_for_platform_family(
      'debian' => 'grub-install',
      'rhel' => 'grub2-install',
    )
    # device of root-mount, strip off partition
    # note that this is a hack and it doesn't support properly dm devices
    d = node.device_of_mount('/').gsub(/p?\d+$/, '')
    unless d && !d.empty? && !d.start_with?('/dev/mapper')
      d = '/dev/sda'
    end
    "/usr/sbin/#{cmd} #{d}"
  }
  action :nothing
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

# For grub 2, we write both efi and bios config files
[
  { :type => 'bios', :mode => '0644' },
  { :type => 'efi', :mode => '0700' },
].each do |tpl|
  # efi command suffixing is a special case in grub2 that only applies
  # to x86_64.
  efi_command = tpl[:type] == 'efi' && node.x64?

  template "grub2_config_#{tpl[:type]}" do
    only_if do
      node['platform_family'] == 'rhel' && node['fb_grub']['kernels'] &&
        node['fb_grub']['version'] == 2
    end
    path lazy { node['fb_grub']["_grub2_config_#{tpl[:type]}"] }
    source 'grub2.cfg.erb'
    owner 'root'
    group 'root'
    mode tpl[:mode]
    variables(
      {
        'linux_statement' => efi_command ? 'linuxefi' : 'linux',
        'initrd_statement' => efi_command ? 'initrdefi' : 'initrd',
      },
    )
  end
end

# cleanup configs for the grub major version that we're not using
['_grub_config_bios', '_grub_config_efi'].each do |tpl_name|
  file "cleanup #{tpl_name}" do
    not_if { node['fb_grub']['version'] == 1 }
    path lazy { node['fb_grub'][tpl_name] }
    action :delete
  end
end

directory "cleanup #{grub_base_dir}" do
  not_if { node['fb_grub']['version'] == 1 }
  path grub_base_dir
  action :delete
  recursive true
end

['_grub2_config_bios', '_grub2_config_efi'].each do |tpl_name|
  file "cleanup grub2_config #{tpl_name}" do
    not_if { node['fb_grub']['version'] == 2 }
    path lazy { node['fb_grub'][tpl_name] }
    action :delete
  end
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
