# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_storage
# Recipes:: default
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

cookbook_file '/sbin/mount.rtxfs' do
  only_if { node.centos? }
  owner 'root'
  group 'root'
  mode '0755'
end

# fsck for XFS with realtime devices (rtxfs filesystem type)
cookbook_file '/sbin/fsck.rtxfs' do
  only_if { node.centos? }
  owner 'root'
  group 'root'
  mode '0755'
end

directory FB::Storage::REPLACED_DISKS_DIR do
  owner 'root'
  group 'root'
  mode '0755'
end

# we use these to disable things while setuping up storage so make
# sure the directories exist
%w{
  /run/udev/rules.d
  /run/systemd/system-generators
}.each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

whyrun_safe_ruby_block 'validate storage options' do
  not_if { node['fb_storage']['devices'].empty? }
  block do
    # Mac doesn't have node['block_device'] .... and probably other stuff
    if node.macos?
      fail 'fb_storage: The `storage` API does not support MacOSX'
    end

    # Same with FIO cards.
    if node.device_of_mount('/').include?('fio')
      fail 'fb_storage: The `storage` API does not support ' +
        'machines with root devices on FIO cards.'
    end
    storage = node['fb_storage'].to_hash
    seen_mountpoints = []
    if storage['devices'] && !storage['devices'].is_a?(Array)
      fail 'fb_storage: The `devices` key in the Storage API ' +
        'is set but is not an array. It must be an array of devices.'
    end
    storage['devices'].each_with_index do |device, didx|
      next if device['_skip']

      unless device['partitions'].is_a?(Array)
        fail "fb_storage: The #{didx} device in the Storage API " +
          'has an `partitions` key that is not an array. It must be an array ' +
          'of partitions'
      end
      num_partitions = device['partitions'].count
      if device['whole_device']
        Chef::Log.warn(
          "fb_storage: 'whole_device' set on device #{didx}, " +
          'this is not recommended',
        )
        if num_partitions > 1
          fail "fb_storage: Device #{didx} specified 'whole_device'" +
            " but #{num_partitions} partitions. Exactly 1 required for " +
            '\'whole_device\''
        end
        if device['partitions'][0]['partition_start'] ||
           device['partitions'][0]['partition_end']
          fail "fb_storage: Device #{didx} specified 'whole_device'" +
            'but also specified a partition size. These are incompatible'
        end
      end
      device['partitions'].each_with_index do |partition, pidx|
        # if you specify a partition sizing you must specify both sides
        if (partition['partition_start'] && !partition['partition_end']) ||
           (!partition['partition_start'] && partition['partition_end'])
          fail 'fb_storage: You must specify both a partition ' +
            'start and end'
        end
        # If we have sizes, validate them
        if partition['partition_start']
          pmsg = 'fb_storage: Invalid partition start value ' +
                 "'%s' specified on device #{didx} parition #{pidx}. " +
                 'It must be a number with an optional suffix of %%kmgt'
          %w{start end}.each do |disp|
            unless partition["partition_#{disp}"].match(
              /^\d+(\.\d+)?([KkMmGgTt\%](iB)?)?$/,
            )
              fail format(pmsg, partition["partition_#{disp}"])
            end
          end
        elsif num_partitions > 1
          fail 'fb_storage: If you want more than one partition, ' +
            'you must specify size of each, but no size was specified for ' +
            " device #{didx} partition #{pidx}"
        end
        if partition['_swraid_array'] && partition['_swraid_array_journal']
          fail "fb_storage: device #{didx} partition #{pidx} is " +
            "set as both a member of array #{partition['_swraid_array']} " +
            "and a journal of array #{partition['_swraid_array_journal']}. " +
            'This is invalid, please remove one of these.'
        end
        unless partition['label'] || partition['_swraid_array'] ||
               partition['_swraid_array_journal'] ||
               partition['_xfs_rt_metadata'] ||
               partition['_xfs_rt_data'] ||
               partition['_xfs_rt_rescue']
          Chef::Log.debug(
            'fb_storage: Adding default label of mount_point to ' +
            "#{partition['mount_point']}(partition #{pidx})",
          )
          node.default['fb_storage']['devices'][didx][
            'partitions'][pidx]['label'] = partition['mount_point']
        end
        if partition['mount_point']
          if seen_mountpoints.include?(partition['mount_point'])
            fail 'fb_storage: Mount point ' +
              "#{partition['mount_point']} specified multiple times."
          end
          seen_mountpoints << partition['mount_point']
        end
      end
    end
    storage['arrays']&.each_with_index do |array, aidx|
      next if array['_skip']
      # this is roughly the same logic as the label in the partition
      # loop above... but I don't see a good way of abstracting it out

      next if array['_skip']

      if array['whole_device']
        fail "fb_storage: 'whole_device' was set on array #{aidx}" +
          ", but that's not a valid setting on an array."
      end
      if seen_mountpoints.include?(array['mount_point'])
        fail "fb_storage: Mount point #{array['mount_point']}" +
          ' specified multiple times.'
      end
      seen_mountpoints << array['mount_point']
      unless array['label']
        Chef::Log.debug(
          'fb_storage: Adding default label of mount_point to ' +
          "#{array['mount_point']}(array #{aidx})",
        )
        node.default['fb_storage']['arrays'][aidx][
          'label'] = array['mount_point']
      end
    end
  end
end

ohai 'filesystem' do
  if node['filesystem2']
    plugin 'filesystem2'
  else
    plugin 'filesystem'
  end
  action :nothing
end

ruby_block 'convert persistent storage file' do
  # simple only_if to short-circuit if we don't use Storage API
  # or aren't in the conversion shard
  only_if do
    !node['fb_storage']['devices'].empty? &&
      FB::Storage.can_use_dev_id?(node)
  end
  # now the actual idempotency check
  only_if do
    x = FB::Storage.persistent_data_file_version
    x && x != 2
  end
  block do
    FB::Storage.convert_persistent_data_file
  end
end

fb_storage_format_devices 'go' do
  not_if { node['fb_storage']['devices'].empty? }
  do_reprobe lazy { node['fb_storage']['format']['reprobe_before_repartition'] }
  # fb_fstab won't mount properly if we don't update data.
  notifies :reload, 'ohai[filesystem]', :immediately
end

template '/etc/mdadm.conf' do
  only_if do
    # we are enabled...
    !node['fb_storage']['devices'].empty? &&
      # and we manage arrays
      node['fb_storage']['arrays'] &&
      !node['fb_storage']['arrays'].empty? &&
      # and we've been asked to create this
      node['fb_storage']['manage_mdadm_conf']
  end
  owner 'root'
  group 'root'
  mode '0755'
end

file '/var/chef/storage_api_active' do
  not_if { node['fb_storage']['devices'].empty? }
  owner 'root'
  group 'root'
  mode '0644'
end
