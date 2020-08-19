# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

module FB
  class Storage
    module FormatDevicesProvider
      FSTAB_GENERATOR_FILE =
        '/run/systemd/system-generators/systemd-fstab-generator'.freeze
      UDEV_MDADM_RULE =
        '/run/udev/rules.d/65-md-incremental.rules'.freeze
      def device_is_mounted?(device)
        devices = node.filesystem_data['by_device'].keys
        devices.select! { |x| x == device || x.start_with?(device) }
        devices.each do |this_device|
          if node.filesystem_data['by_device'][this_device] &&
             node.filesystem_data['by_device'][this_device]['mount_point']
            return true
          end
        end
        false
      end

      def filter_arrays_with_mounted_drives(arrays, storage)
        safe_arrays = []
        arrays.each do |array|
          can_do = true
          storage.arrays[array]['members'].each do |device|
            if node.filesystem_data['by_device'][device] &&
               node.filesystem_data['by_device'][device]['mount_point']
              can_do = false
              break
            end
          end
          if can_do
            safe_arrays << array
          end
        end
        safe_arrays
      end

      # Helper function to filter down work to be done
      def filter_work(needs_work, how_to_collapse, storage)
        case how_to_collapse
        when :all
          {
            :devices => needs_work[:missing_partitions] +
              needs_work[:mismatched_partitions],
            :partitions => needs_work[:missing_filesystems] +
              needs_work[:mismatched_filesystems],
            :arrays => needs_work[:missing_arrays] +
              needs_work[:mismatched_arrays],
          }
        when :missing
          {
            :devices => needs_work[:missing_partitions],
            :partitions => needs_work[:missing_filesystems],
            # for missing arrays, we have to do more work below
            :arrays => filter_arrays_with_mounted_drives(
              needs_work[:missing_arrays], storage
            ),
          }
        when :filesystems
          {
            :devices => [],
            :partitions => needs_work[:missing_filesystems] +
              needs_work[:mismatched_filesystems],
            :arrays => [],
          }
        end
      end

      def override_file_applies?(verb, fname, quiet = false)
        if File.exist?(fname)
          base_msg = "fb_storage: System has #{fname} file present"
          if node['fb_storage']['_clowntown_override_file_method']
            ret = node['fb_storage']['_clowntown_override_file_method'].call(
              node, verb, fname, quiet
            )
            unless quiet
              if ret
                Chef::Log.warn(
                  "#{base_msg} and the override check succeeded, will " +
                  "#{verb} all disks on this system",
                )
              else
                Chef::Log.warn(
                  "#{base_msg} but the override check failed, therefore we " +
                  'are ignoring it',
                )
              end
            end
            return ret
          end
          unless quiet
            Chef::Log.warn(
              "#{base_msg} but the override check method is not defined, " +
              'therefore we are ignoring it.',
            )
          end
          return false
        end
        false
      end

      def erase_all?(format_rules, quiet = false)
        if node.firstboot_tier? && format_rules['firstboot_eraseall'] &&
            !File.exist?(FB::Storage::ALREADY_ERASED_ALL_FILE)
          unless quiet
            Chef::Log.info(
              'fb_storage: Erasing and rebuilding due to ' +
              '`firstboot_eraseall`',
            )
          end
          return true
        end
        override_file_applies?(
          'erase',
          FB::Storage::ERASE_ALL_FILE,
          quiet,
        )
      end

      def converge_all?(format_rules, quiet = false)
        if node.firstboot_tier? && format_rules['firstboot_converge']
          unless quiet
            Chef::Log.info(
              'fb_storage: Allowed to converge disks on this ' +
              'system because we are in firstboot_tier',
            )
          end
          return true
        end
        override_file_applies?(
          'converge',
          FB::Storage::CONVERGE_ALL_FILE,
          quiet,
        )
      end

      # Hash#merge in ruby doesn't do deep-merges that handle arrays
      # at all, so the array on the RHS always wins. We need this smarter
      # merge.
      def merge_work(lhs, rhs)
        {
          :devices => (lhs[:devices] + rhs[:devices]).uniq,
          :partitions => (lhs[:partitions] + rhs[:partitions]).uniq,
          :arrays => (lhs[:arrays] + rhs[:arrays]).uniq,
        }
      end

      def stash_stats(needs_work)
        stats = {
          'out_of_spec' => 0,
          'out_of_spec.count' => 0,
        }
        needs_work.each do |key, val|
          next if key == :incomplete_arrays

          unless val.empty?
            stats['out_of_spec'] = 1
          end
          stats['out_of_spec.count'] += val.length
          stats["#{key}.count"] = val.length
        end
        node.default['fb_storage']['_stats'] = stats
      end

      def get_primary_work(storage)
        needs_work = storage.out_of_spec
        all_storage = storage.all_storage
        # Stash these away for reporting purposes:
        stash_stats(needs_work)
        Chef::Log.debug(
          "fb_storage: Out of spec storage: #{needs_work}",
        )
        Chef::Log.debug(
          "fb_storage: All storage: #{all_storage}",
        )
        format_rules = node['fb_storage']['format'].to_hash
        Chef::Log.debug(
          "fb_storage: Converge rules: #{format_rules}",
        )
        to_do = {
          :devices => [], :partitions => [], :arrays => []
        }

        # First look at firstboot - these stand by themselves.
        if erase_all?(format_rules)
          return all_storage
        elsif converge_all?(format_rules)
          return filter_work(needs_work, :all, storage)
        end

        # hotswap automation is orthogonal to normal "out of spec"-ness, so do
        # that no matter what if we're allowed to in addition to the rest.
        if format_rules['hotswap']
          Chef::Log.debug(
            'fb_storage: Allowed to converge disks on this system ' +
            'that external automation has specified',
          )

          storage.hotswap_disks.each do |disk|
            unless storage.config[disk]
              fail 'fb_storage: external automation says to repair disk ' +
                   "'#{disk}' but no config for this device exists"
            end
          end
          devices = storage.hotswap_disks.reject do |disk|
            storage.config[disk]['_skip']
          end
          partitions = devices.map do |disk|
            FB::Storage.partition_names(
              disk,
              storage.config[disk],
            )
          end.flatten
          # if there are any RAID0 arrays that reference these partitions,
          # we'll need to rebuild those as well
          arrays = []
          Chef::Log.debug(
            'fb_storage: Determining what RAID0 arrays or Hybrid ' +
            'XFS filesystems need rebuilding, and what arrays need to be ' +
            'filled to accommodate automation request...',
          )
          partitions.each do |p|
            storage.arrays.each do |array, info|
              if (info['members'].include?(p) ||
                  info['journal']&.include?(p)) &&
                 ['hybrid_xfs', 0].include?(info['raid_level'])
                arrays << array
              end
            end
          end
          arrays.uniq!
          unless arrays.empty?
            Chef::Log.info(
              'fb_storage: The following RAID0 arrays must be ' +
              "rebuilt because a member disk has been replaced: #{arrays}",
            )
          end
          to_do = merge_work(
            to_do,
            {
              :devices => devices,
              :partitions => partitions + arrays,
              :arrays => arrays,
            },
          )
        end

        if format_rules['missing_filesystem_or_partition']
          Chef::Log.debug(
            'fb_storage: Allowed to converge disks with missing ' +
            'partitions or filesystems on this system',
          )
          to_do = merge_work(to_do, filter_work(needs_work, :missing, storage))
        end

        if format_rules['mismatched_filesystem_or_partition']
          Chef::Log.debug(
            'fb_storage: Allowed to converge disks incorrect ' +
            'partitions or filesystems on this system',
          )
          to_do = merge_work(to_do, filter_work(needs_work, :all, storage))
        elsif format_rules['mismatched_filesystem_only']
          Chef::Log.debug(
            'fb_storage: Allowed to converge disks incorrect ' +
            'filesystems on this system',
          )
          to_do = merge_work(to_do, filter_work(needs_work, :filesystems,
                                                storage))
        end

        # ## ARRAYS WE CAN CONVERGE
        #   Walk arrays we want to touch, and if we're allowed to touch all of
        #   their member devices, touch the array
        partitions_set = Set.new(to_do[:partitions])
        (
          needs_work[:missing_arrays] + needs_work[:mismatched_arrays]
        ).each do |array|
          next if to_do[:arrays].include?(array)

          if Set.new(storage.arrays[array]['members']) <= partitions_set
            to_do[:arrays] << array
          end
        end

        to_do
      end

      def fill_in_dynamic_work(to_do, storage)
        needs_work = storage.out_of_spec
        format_rules = node['fb_storage']['format'].to_hash

        # ## MISSING ARRAY MEMBERS
        #   If we have an array with "missing members" and we're allowed to
        #   to fix missing things, add the device to the array
        to_do[:fill_arrays] = {}
        if format_rules['missing_filesystems_or_partitions']
          needs_work[:incomplete_arrays].each do |array, missing|
            to_do[:fill_arrays][array] =
              missing.reject { |x| device_is_mounted?(x) }
          end
        end

        # plus any members we know we're about to remove we'll want to re-add
        to_do[:partitions].each do |p|
          storage.arrays.each do |array, info|
            # if we're already rebuilding this array, don't add it to the
            # fill list
            next if to_do[:arrays].include?(array)
            # we can't fill hybrid_xfs arrays
            next if info['raid_level'] == 'hybrid_xfs'

            if info['members'].include?(p)
              to_do[:fill_arrays][array] ||= []
              to_do[:fill_arrays][array] << p
            end
          end
        end

        # We'll want to uniq-ify those:
        to_do[:fill_arrays].each_key do |array|
          to_do[:fill_arrays][array].uniq!
        end

        # ## ARRAYS WE CAN STOP
        #   Any array we're not configured to care about and were we will nuke
        #   all of it's members, we stop
        #
        # This is necessary in the case you have an array you will take all
        # devices out of. We handle that properly, but you'll be left with a
        # failed empty array just hanging around.
        if converge_all?(format_rules, true) || erase_all?(format_rules, true)
          to_do[:stop_arrays] = needs_work[:extra_arrays]
        else
          to_do[:stop_arrays] = []
          partitions_set = Set.new(to_do[:partitions])
          needs_work[:extra_arrays].each do |array|
            info = node['mdadm'][File.basename(array)]
            members_set = Set.new(info['members'].map { |x| "/dev/#{x}" })
            if members_set <= partitions_set
              Chef::Log.info(
                'fb_storage: We will rebuild every device in ' +
                "#{array} **and** it's not an array we're configured to want " +
                'so we are unmounting and stopping it.',
              )
              to_do[:stop_arrays] << array
            end
          end
        end

        to_do
      end

      # Takes things that need to be converted according to the Storage class
      # and filters it for what we're allowed to converge
      def filesystems_to_format(storage)
        to_do = get_primary_work(storage)

        # all physical hardware, and desired arrays are configured out
        #
        # but non-physical hardware requires some extrapolation based on that
        # data so here we figure out arrays to be filled, cleaned up, etc.
        fill_in_dynamic_work(to_do, storage)
      end

      def clear_flag_files(devices, storage)
        # Any flag files that are there which correspond to disks we configured
        # or are configured as disks to skip, we remove the flag file.
        storage.hotswap_disks.each do |disk|
          if devices.include?(disk) || storage.config[disk]['_skip']
            filepath = ::File.join(
              FB::Storage::REPLACED_DISKS_DIR,
              ::File.basename(disk),
            )
            ::File.delete(filepath)
          end
        end

        # If we were told by a human to converge all storage, remove that flag
        # now that we're done.
        [
          FB::Storage::CONVERGE_ALL_FILE,
          FB::Storage::ERASE_ALL_FILE,
        ].each do |flagfile|
          if File.exist?(flagfile)
            ::File.delete(flagfile)
          end
        end
      end

      def set_flag_files
        format_rules = node['fb_storage']['format'].to_hash
        indicator_file = FB::Storage::ALREADY_ERASED_ALL_FILE
        if node.firstboot_tier? && format_rules['firstboot_eraseall'] &&
            !File.exist?(indicator_file)
          FileUtils.touch(indicator_file) # ~FB029
        end
      end

      # First build missing partitions
      def partition_storage(devices, storage)
        devices.each do |device|
          Chef::Log.debug("fb_storage: Partitioning device #{device}")
          dev_settings = storage.config[device]
          unless dev_settings
            fail "fb_storage: No info for #{device}"
          end

          # storage handler
          sh = FB::Storage::Handler.get_handler(device, node)
          sh.wipe_device
          sh.prep_device
          sh.partition_device(dev_settings)
          sh.condition_device
        end
      end

      # Then format the partitions
      def format_storage(partitions, storage)
        Chef::Log.debug(
          "fb_storage: formatting #{partitions}",
        )
        partitions.each do |partition|
          device = FB::Storage.device_name_from_partition(partition)
          # if this partition is really a device, and if
          # that device is supposed to be treated as an FS...
          device_config = nil
          if storage.config[device]
            device_config = storage.config[device]
          elsif storage.arrays[device]
            device_config = storage.arrays[device]
          end
          Chef::Log.debug(
            "fb_storage: Device config for #{partition} " +
            "is #{device_config}",
          )

          if device == partition && device_config['whole_device']
            config = device_config['partitions'][0]
          elsif device_config['raid_level']
            config = device_config
          else
            partnum = partition.match(/([0-9]+)$/)[0].to_i
            # the ' - 1' is because sdb1 is the 0th index
            config = device_config['partitions'][partnum - 1]
          end

          Chef::Log.debug(
            "fb_storage: Partition config for #{partition} " +
            "is #{config}",
          )

          # If member devices of either MD arrays or Hybrid XFS filesystems
          # skip it, it'll be setup for as part of array setup.
          #
          # Also skip if the user asked is to skip (_no_mkfs)
          if config['_swraid_array'] || config['_swraid_array_journal'] ||
             config['_xfs_rt_data'] || config['_xfs_rt_metadata'] ||
             config['_xfs_rt_rescue'] || config['_no_mkfs']
            Chef::Log.debug(
              "fb_storage: Skipping because we're a member " +
              'of an array, or were asked not to make a filesystem',
            )
            next
          end
          sh = FB::Storage::Handler.get_handler(device, node)
          sh.prep_partition(partition)
          sh.format_partition(
            partition,
            config,
          )
          sh.condition_partition(partition)
        end
      end

      def nuke_arrays(arrays, storage)
        # we need to wipe all devices *then* build new devices. Otherwise
        # you can end up in a situation where sdd used to be in md0, but is now
        # in md1... so we build md0, but then when we go to build md1 we see a
        # member device used to be in md0 and we stop it, even though we just
        # built it.
        Chef::Log.debug(
          'fb_storage: Removing arrays we plan to rebuild',
        )
        arrays.each do |array|
          config = storage.arrays[array]
          if config['raid_level'] == 'hybrid_xfs'
            # Get a handler on the device of the journal partition
            sh = FB::Storage::Handler.get_handler(
              FB::Storage.device_name_from_partition(
                config['journal'],
              ),
              node,
            )
            # and them unmount that partition
            sh.umount_by_partition(config['journal'])
          else
            sh = FB::Storage::Handler.get_handler(array, node)
            sh.stop
            sh.wipe_member_devices(storage.arrays[array])
          end
        end
      end

      def stop_unneeded_arrays(arrays)
        # Any array we're not configured to care about and were we will nuke
        # all of it's members, we stop
        #
        # This is necessary in the case you have an array you will take all
        # devices out of. We handle that properly, but you'll be left with a
        # failed empty array just hanging around.
        Chef::Log.debug(
          'fb_storage: Stopping arrays we plan to empty',
        )
        arrays.each do |array|
          sh = FB::Storage::Handler.get_handler(array, node)
          sh.stop
        end
      end

      def build_arrays(arrays, storage)
        arrays.each do |array|
          config = storage.arrays[array]
          next if config['raid_level'] == 'hybrid_xfs'

          sh = FB::Storage::Handler.get_handler(array, node)
          sh.build(config)
        end
      end

      def fill_arrays(arrays, storage)
        arrays.each do |array, missing|
          to_add = missing
          cmd = "mdadm #{array}"
          journal = storage.arrays[array]['journal']
          if journal && missing.include?(journal)
            to_add.delete(journal)
            Chef::Log.warn(
              "fb_storage: A journal is missing from #{array} " +
              "(#{journal}) - but mdadm doesn't allow adding a journal to " +
              ' a live array, so doing nothing. Performance will sufer.',
            )
            #
            # Note, we would do
            #   cmd << " --add-journal #{journal}"
            # but that requires the array to be read-only
          end
          unless missing.empty?
            cmd << " --add #{missing.join(' ')}"
          end
          Chef::Log.info(
            'fb_storage: Adding missing members ' +
            "(#{missing.join(' ')}) to #{array}",
          )
          Mixlib::ShellOut.new(cmd).run_command.error!
        end
      end

      def systemd_daemon_reload
        Mixlib::ShellOut.new('systemctl daemon-reload').run_command.error!
      end

      # Disabling the generator and reloading systemd will drop all of the
      # auto-generated unit files. Therefore systemd won't mount devices
      # as we partition them
      def disable_systemd_fstab_generator
        return unless node.systemd?

        Chef::Log.info(
          'fb_storage: Disabling systemd fstab generator',
        )
        # The way one masks units in systemd is by making a symlink to /dev/null
        # (an empty file will also work). For most units you can do
        # `systemctl mask $UNIT`, but not in this case.
        #
        # While theoretically you could put a real file in /run, since it's a
        # tmpfs, that's not a thing you'd actually do, so in practice it's
        # effectively just a place to mask things.
        unless File.exist?(FSTAB_GENERATOR_FILE)
          FileUtils.ln_s('/dev/null', FSTAB_GENERATOR_FILE)
        end
        unless File.exist?(UDEV_MDADM_RULE)
          FileUtils.ln_s('/dev/null', UDEV_MDADM_RULE)
        end
        systemd_daemon_reload
      end

      # put it back...
      def enable_systemd_fstab_generator
        return unless node.systemd?

        Chef::Log.info(
          'fb_storage: Enabling systemd fstab generator',
        )
        ::File.unlink(FSTAB_GENERATOR_FILE)
        ::File.unlink(UDEV_MDADM_RULE)
        systemd_daemon_reload
      end

      def converge_storage(to_do, storage)
        disable_systemd_fstab_generator
        begin
          nuke_arrays(to_do[:arrays], storage)
          stop_unneeded_arrays(to_do[:stop_arrays])
          partition_storage(to_do[:devices], storage)
          build_arrays(to_do[:arrays], storage)
          format_storage(to_do[:partitions], storage)
          if to_do[:fill_arrays]
            fill_arrays(to_do[:fill_arrays], storage)
          end
          clear_flag_files(to_do[:devices], storage)
          set_flag_files
        ensure
          enable_systemd_fstab_generator
        end
      end
    end
  end
end
