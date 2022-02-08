#
# Cookbook Name:: fb_grub
# Recipe:: validate
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

whyrun_safe_ruby_block 'initialize_grub_locations' do
  block do
    bootdisk_guess = 'hd0'

    if Pathname.new('/boot').mountpoint?
      boot_device = node.device_of_mount('/boot')
      boot_label = node.filesystem_data['by_mountpoint']['/boot']['label']
      boot_uuid = node.filesystem_data['by_mountpoint']['/boot']['uuid']
      node.default['fb_grub']['path_prefix'] = ''
    else
      boot_device = node.device_of_mount('/')
      boot_label = node.filesystem_data['by_mountpoint']['/']['label']
      boot_uuid = node.filesystem_data['by_mountpoint']['/']['uuid']
      node.default['fb_grub']['path_prefix'] = '/boot'
    end

    if node['fb_grub']['use_labels'] && node['fb_grub']['use_uuids']
      fail 'fb_grub: must choose one of use_labels or use_uuids'
    end

    if node['fb_grub']['use_labels']
      if node['fb_grub']['version'] < 2
        fail 'fb_grub: Booting by label requires grub2.'
      end

      node.default['fb_grub']['_root_label'] = boot_label

      # For tboot, we have to specify the full path to the modules.
      # They are in /usr/lib/grub , so we need the label for the root disk
      slash_label = node.filesystem_data['by_mountpoint']['/']['label']
      if slash_label
        node.default['fb_grub']['_module_label'] = slash_label
      end
    elsif node['fb_grub']['use_uuids']
      if node['fb_grub']['version'] < 2
        fail 'fb_grub: Booting by label requires grub2.'
      end

      node.default['fb_grub']['_root_uuid'] = boot_uuid

      slash_uuid = node.filesystem_data['by_mountpoint']['/']['uuid']
      if slash_uuid
        node.default['fb_grub']['_module_uuid'] = slash_uuid
      end
    else
      # We are apparently not using labels, so we have to do some detective
      #  work. If something did put a .before_chef file in place, we will
      # extract the root_device from it. If the file does not exist (e.g. on
      # older existing systems), we will use our old heuristics.
      original_grub_config = '/root/grub.before_chef'
      if File.exist?(original_grub_config)
        content = File.read(original_grub_config)
        original_root_device = FB::Grub.extract_root_device(content)
        original_device_hints = FB::Grub.extract_device_hints(content)
        if original_root_device
          node.default['fb_grub']['root_device'] = original_root_device
          Chef::Log.debug(
            "fb_grub: Re-using existing root device: #{original_root_device}",
          )
          node.default['fb_grub']['_device_hints'] = original_device_hints
          Chef::Log.debug(
            "fb_grub: Found #{original_device_hints.size} grub device hints.",
          )
        else
          Chef::Log.warn(
            "fb_grub: Can't parse grub config: #{original_grub_config}",
          )
        end
      end

      # If nothing has set the root_device so far, fall back to the old logic
      # and set it by using the hardcoded boot_disk parameter
      unless node['fb_grub']['root_device']
        # This is the old, somewhat broken logic to use a hardcoded root
        # udev block device partitions start at 1
        # grub disks start at 0
        if boot_device
          m = boot_device.match(/[0-9]+$/)
          unless m
            fail 'fb_grub: cannot parse the boot device!'
          end
        else
          fail 'fb_grub: cannot find the boot device!'
        end

        grub_partition = m[0].to_i
        grub_partition -= 1 if node['fb_grub']['version'] < 2
        # In case somebody has set an override, just take whatever they set
        # otherwise just use the default and hope for the best.
        boot_disk = node['fb_grub']['boot_disk'] || bootdisk_guess
        root_device = "#{boot_disk},#{grub_partition}"
        Chef::Log.info("fb_grub: Using old root device logic: #{root_device}")
        node.default['fb_grub']['root_device'] = root_device
      end
    end

    # some provisioning configurations do not properly label the root filesystem
    # Ensure grub is put down with the label matching the fs mounted at / that
    # has a valid uuid or label. This will skip over things like rootfs mounts.
    node.default['fb_grub']['rootfs_arg'] = 'LABEL=/'
    label = node.filesystem_data['by_mountpoint']['/']['label']
    uuid = node.filesystem_data['by_mountpoint']['/']['uuid']
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
        if os_device
          m = os_device.match(/[0-9]+$/)
          unless m
            fail 'fb_grub: cannot parse the OS device!'
          end
        else
          fail 'fb_grub: cannot find the OS device!'
        end

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

      # So that we can use btrfs subvolumes and still insmod filesystems
      if node.root_btrfs?
        node.default['fb_grub']['_grub2_copy_path'] = node['fb_grub'][
          '_grub2_module_path']
        node.default['fb_grub']['_module_label'] = node['fb_grub'][
          '_root_label']
        node.default['fb_grub']['_grub2_module_path'] = node['fb_grub'][
          'path_prefix']
      end
    end
    node.default['fb_grub']['_decided_boot_disk'] = boot_disk
  end
end

if node.root_btrfs?
  mount_opts = FB::Fstab.get_base_mount_opts(node, '/')
  # in this case we'd be &.'ing all the way down, so the unless is actually
  # cleaner
  # rubocop:disable Style/SafeNavigation
  unless mount_opts.nil?
    mount_opts.split(',').each do |opt|
      if opt.include?('subvolid=') || opt.include?('subvol=')
        node.default['fb_grub']['_rootflags'] = opt
      end
    end
  end
  # rubocop:enable Style/SafeNavigation
end
