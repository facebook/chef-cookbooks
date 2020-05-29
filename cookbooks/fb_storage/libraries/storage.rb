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
  # The storage class takes the user-specificed config, and provides useful
  # interfaces to it. It maps it to real devices, and also generates fstab
  # configs from it. There are also some util class methods
  class Storage
    REPLACED_DISKS_DIR = '/var/chef/hotswap_replaced_disks'.freeze
    CONVERGE_ALL_FILE = '/var/chef/storage_force_converge_all'.freeze
    ERASE_ALL_FILE = '/var/chef/storage_force_erase_all'.freeze
    ALREADY_ERASED_ALL_FILE = '/var/chef/.storage_already_erased_all'.freeze
    PREVIOUS_DISK_ORDER = '/etc/.chef_disk_order'.freeze
    FORCE_WRITE_CUSTOM_DISK_ORDER =
      '/var/chef/storage_force_write_custom_disk_order'.freeze
    DEV_ID_DIR = '/dev/disk/by-id'.freeze

    # 'size' from sysfs always assumes 512 byte blocks
    SECTOR_SIZE = 512
    # Helper function for hybrid XFS users. Given the index (into
    # `eligible_devices` of the device to be used for metadata, and the number
    # of filesystems we expect to create, it will return the size of each
    # metadata partition.
    def self.hybrid_xfs_md_part_size(node, md_idx, num_fses,
                                     sectors_reserved = 0)
      device_sectors = self.hybrid_md_idx_size(node, md_idx)
      sectors_available = device_sectors - sectors_reserved
      # The divide-by 2K and multiply-by 2K is just to get into page
      # alignment
      sectors_per_part = ((sectors_available / num_fses) / 2048) * 2048
      # MB per partition - get bytes, deviced by 1MB
      ((sectors_per_part * SECTOR_SIZE) / (1024 * 1024))
    end

    def self.hybrid_md_idx_size(node, md_idx)
      devs = self.sorted_devices(node, FB::Fstab.get_in_maint_disks)
      md_dev = devs[md_idx]

      node['block_device'][md_dev]['size'].to_i
    end

    def self.mountpoint_uses_whole_device(node, mp)
      # if the mountpoint doesn't exist, we're new and can build it
      # on a partition
      return false unless node.filesystem_data['by_mountpoint'][mp]

      dev = node.filesystem_data['by_mountpoint'][mp]['devices'][0]
      # return false if we find a partition, keep it as such
      # In this case I want this code very clear, so we're violating this lint
      # rule
      # rubocop:disable Style/IfInsideElse
      if dev.match(/(nvme|ether)/)
        return false if dev.match(/p\d+$/)
      else
        return false if dev.match(/\d+$/)
      end
      # rubocop:enable Style/IfInsideElse
      # if we're not new AND we didn't find a partition, then we can keep
      # this on a whole device
      true
    end

    # List of devices eligble for managing by the fb_storage storage system,
    # i.e., non-root devices
    def self.eligible_devices(node)
      root_dev = node.device_of_mount('/')
      return [] unless root_dev

      if root_dev
        root_dev = root_dev.split('/').last
      end
      node['block_device'].to_hash.reject do |x, _y|
        ['ram', 'loop', 'dm-', 'sr'].include?(x.delete('0-9')) ||
          root_dev&.start_with?(x) ||
          x.start_with?('md')
      end.keys
    end

    # Return the short device name of the physical root device, i.e. 'sda',
    # not to be confused with '/dev/sda' or '/dev/sda3'
    def self.root_device_name(node)
      # This could be a bare device (/dev/md0) or a partition (/dev/sda1)
      device_or_partition = node.device_of_mount('/')
      device_or_partition_base = File.basename(device_or_partition)

      if node['block_device'][device_or_partition_base]
        return device_or_partition_base
      else
        root_dev = device_name_from_partition(device_or_partition)
        return File.basename(root_dev)
      end
    end

    # Give a device path and a partition number, return the proper
    # partition's device path
    def self.partition_device_name(device, partnum)
      prefix = /[0-9]$/.match(device) ? 'p' : ''
      "#{device}#{prefix}#{partnum}"
    end

    # Given a device including a partiition, return just the device without
    # the partition. i.e.
    #   /dev/sda1 -> /dev/sd
    #   /dev/md0p0 -> /dev/md0
    #   /dev/nvme0n1p0 -> /dev/nvm0n1
    #
    # In reality we can just check for the RE /[0-9]+p[0-9]+$/ to know if
    # we need to drop a pX or an X...
    #
    # HOWEVER, since you can make a filesystem on a whole device (we generally
    # frown upon it, but you never know what you'll run into), this method can
    # be called with a device path that actually isn't a partition. In such
    # cases that can give you the wrong behavior. This is why
    # https://github.com/facebook/chef-cookbooks/commit/22d564a3be86a5258c4a404da997bfc3901a3fe2
    # was needed.
    #
    # So, for devices that we *know* would require such
    # a thing, we also force them to use that regex, so if someone erroneously
    # passes in `/dev/md0`, we give them back `/dev/md0`.
    def self.device_name_from_partition(partition)
      if partition =~ /[0-9]+p[0-9]+$/ || partition =~ %r{/(nvme|etherd|md|nbd)}
        re = /p[0-9]+$/
      else
        re = /[0-9]+$/
      end
      partition.sub(re, '')
    end

    # External automation can pass us disks to rebuild for hot-swap. In order
    # to ensure atomicity, we have one file per device, named by that device.
    def self.disks_from_automation
      result = []
      if ::File.directory?(FB::Storage::REPLACED_DISKS_DIR)
        Dir.new(FB::Storage::REPLACED_DISKS_DIR).each do |entry|
          next if ['.', '..'].include?(entry)

          result << "/dev/#{entry}"
        end
      end
      unless result.empty?
        Chef::Log.info(
          'fb_storage: Disks automation requested converging of: ' +
          result.to_s,
        )
      end
      result
    end

    def self.block_device_split(dev)
      if dev.start_with?('sd')
        m = dev.match(/^(sd)([a-z]+)$/)
      elsif dev.start_with?('fio')
        m = dev.match(/^(fio)([a-z]+)$/)
      elsif dev.start_with?('nvme')
        m = dev.match(/^(nvme)(\d+n\d+)$/)
      elsif dev.start_with?('nbd')
        m = dev.match(/^(nbd)(\d+)$/)
      elsif dev.start_with?('vd')
        m = dev.match(/^(vd)([a-z]+)$/)
      end
      unless m
        fail "fb_storage: Cannot parse #{dev} for sorting"
      end

      [m[1], m[2]]
    end

    def self.length_alpha(a, b)
      a.length == b.length ? a <=> b : a.length <=> b.length
    end

    def self.scsi_device_sort(a, b, disk_to_scsi_mapping)
      Chef::Log.debug(
        "fb_storage: scsi_device_sort: Sorting #{a} and #{b}",
      )
      if disk_to_scsi_mapping[a] && !disk_to_scsi_mapping[b]
        Chef::Log.debug(
          "fb_storage: #{a} is on SCSI bus, #{b} is not, #{a} " +
            'sorts first',
        )
        return -1
      elsif !disk_to_scsi_mapping[a] && disk_to_scsi_mapping[b]
        Chef::Log.debug(
          "fb_storage: #{a} is not on SCSI bus, #{b} is, #{b} " +
            'sorts first',
        )
        return 1
      elsif disk_to_scsi_mapping[a] && disk_to_scsi_mapping[b]
        Chef::Log.debug(
          "fb_storage: #{a} and #{b} are both on the SCSI bus " +
            'sorting by address',
        )
        return sort_scsi_slots(disk_to_scsi_mapping[a],
                               disk_to_scsi_mapping[b])
      end
      0
    end

    def self.block_device_sort(a, b, disk_to_scsi_mapping)
      (atype, ainstance) = block_device_split(File.basename(a))
      (btype, binstance) = block_device_split(File.basename(b))
      if atype != btype
        Chef::Log.debug(
          'fb_storage: Types not same sorting by type',
        )
        length_alpha(atype, btype)
      else
        if atype == 'nvme' && btype == 'nvme'
          Chef::Log.debug(
            'fb_storage: Special nvme sorting',
          )
          # nvme is 0n1 or 1n3 or whatever, split in the n
          # and each part can sort as an integer.
          ainstance = ainstance.split('n').map(&:to_i)
          binstance = binstance.split('n').map(&:to_i)
          return ainstance <=> binstance
        end
        Chef::Log.debug(
          'fb_storage: Types are the same, sorting by SCSI',
        )
        r = scsi_device_sort(a, b, disk_to_scsi_mapping)
        # 0 is they both weren't SCSI disks (or they're both in the same
        # SCSI slot, but that is not possible :))
        if r.zero?
          Chef::Log.debug(
            'fb_storage: SCSI sort failed, sorting by name',
          )
          return length_alpha(ainstance, binstance)
        else
          return r
        end
      end
    end

    # sorts shelves themselves
    def self.sort_shelves(a, b)
      a_base = File.basename(a)
      b_base = File.basename(b)
      if a_base.start_with?('sg')
        return a_base.gsub('sg', '').to_i <=> b_base.gsub('sg', '').to_i
      end

      a_array = a_base.split(':').map(&:to_i)
      b_array = b_base.split(':').map(&:to_i)
      a_array <=> b_array
    end

    # sorts disks in disk shelves
    def self.sort_disk_shelves(a, b)
      if a['shelf'] != b['shelf']
        sort_shelves(a['shelf'], b['shelf'])
      else
        a['disk'] <=> b['disk']
      end
    end

    def self.sort_scsi_slots(a, b)
      a.split(':').map(&:to_i) <=> b.split(':').map(&:to_i)
    end

    # returns nil if no previous file
    def self.load_previous_disk_order(include_version = false)
      # size? returns nil if the file does not exist or is 0 bytes.
      #
      # We don't want to fail if someone TOUCHES the file, but we do want to
      # fail if the file is non-0-bytes and we still fail to parse it
      version = disks = nil
      if File.size?(PREVIOUS_DISK_ORDER)
        f = JSON.parse(File.read(PREVIOUS_DISK_ORDER))
        # v1 of the file was just an array of disks
        if f.is_a?(Array)
          version = 1
          disks = f.empty? ? nil : f
        elsif f.is_a?(Hash)
          unless f['version'] == 2
            fail 'fb_storage: Unknown format of persistent-order ' +
              'cache file!'
          end
          version = f['version']
          disklist = []
          f['disks'].each do |id|
            # If we have a corrupted file, ignore it, and re-generate it later
            if id.nil?
              return nil
            end

            sysfile = "#{DEV_ID_DIR}/#{id}"
            if File.exist?(sysfile)
              disklist << File.basename(File.readlink(sysfile))
            else
              Chef::Log.warn(
                "fb_storage: Unable to translate #{id} into" +
                ' drive path - probably replaced disk.',
              )
              # just put the id in there, we won't match it as a disk
              # and know the disk has been removed
              disklist << id
            end
          end
          disks = disklist
        end
        if include_version
          return { 'version' => version, 'disks' => disks }
        else
          return disks
        end
      end
      nil
    end

    # disks parameter is a list of the block devices, i.e. ['sdb', 'sdc', ...]
    # translates a list of disks into a list of global ids, returns a
    # versioned hash
    def self.gen_persistent_disk_data(disks)
      id_list = []
      # id_map maps a device ('sdc') to a global id
      # ('scsi-3600605b00c0c2d9020b8d13611e63d52')
      id_map = {}
      Dir.open(DEV_ID_DIR).each do |entry|
        next if %w{. ..}.include?(entry)

        p = "#{DEV_ID_DIR}/#{entry}"
        id_map[File.basename(File.readlink(p))] = entry
      end
      disks.each do |disk|
        id = id_map[disk]
        if id.nil?
          msg = "fb_storage: Can't convert #{disk} to an id"
          if FB::Fstab.get_in_maint_disks.include?(disk)
            Chef::Log.warn(
              "#{msg}, but it's in maintenance, so using #{disk}",
            )
            id = disk
          else
            fail "fb_storage: Can't convert #{disk} to an id"
          end
        end
        id_list << id
      end
      {
        'version' => 2,
        'disks' => id_list,
      }
    end

    def self.write_out_disk_order(disks, version = 2)
      case version
      when 1
        data = disks
      when 2
        data = gen_persistent_disk_data(disks)
      else
        fail 'fb_storage: Unknown persistent disk format ' +
          "specified: #{version}"
      end
      File.open(PREVIOUS_DISK_ORDER, 'w') do |fd| # ~FB030
        Chef::Log.debug('fb_storage: Writing out disk order')
        fd.write(JSON.generate(data))
      end
    end

    def self.persistent_data_file_version
      x = load_previous_disk_order(true)
      return x ? x['version'] : nil
    end

    # we assume someone has checked with `persistent_data_file_version`
    # before calling this needlessly
    def self.convert_persistent_data_file
      x = load_previous_disk_order
      # just to be safe
      return unless x

      write_out_disk_order(x, 2) unless x.empty?
    end

    # Some hosts cannot use /dev/by-id because some of their devices
    # have no information for mapping (FIO), so we never convert those
    def self.can_use_dev_id?(node)
      !node.virtual? &&
        File.directory?(FB::Storage::DEV_ID_DIR) &&
        node['block_device'].keys.none? do |x|
          x.start_with?('fio', 'nbd', 'ether')
        end
    end

    # now we have both the previous ordering and the new ordering.  We want
    # to keep the previous ordering, but allow disks to have been
    # replaced. Let's say this is our old mapping
    #   sdb, sdc, sdd, sde
    # and then sdc goes away and sdf gets added. what we really want to do
    # is slot 'f' where 'c' was. Our SCSI slot ordering above should always
    # do the right thing and return f in c's slot - but to be extra safe,
    # we always use the existing order to ensure that even if we had some
    # ordering bug before, we don't change the ordering now.
    #
    # So we do this by walking the previous list and noting which slots are
    # now invalid. Using the example above, that means we'd now have a list
    # of [1] (the 1 slot in the array is sdc which is not in the new list).
    #
    # Then we drop all disks on the old list from the new list. That would
    # leave us with only ['sdf']. These two lists should be the same length.
    #
    # Then we slot in each element in the second list to the nth element on
    # our previous ordering based on the first list.
    #
    # This function is only called when the prev set of devices and the new
    # set of devices are not the same
    def self.calculate_updated_order(prev, devs)
      Chef::Log.debug(
        'fb_storage: Attempting to merge old and new config',
      )
      new_mapping = prev.dup
      slots_to_replace = []

      Chef::Log.debug("fb_storage: previous list: #{prev}")
      Chef::Log.debug("fb_storage: current devs: #{devs}")

      prev.each_with_index do |disk, index|
        slots_to_replace << index unless devs.include?(disk)
      end

      new_disks = devs.reject do |disk|
        prev.include?(disk)
      end

      if new_disks.size != slots_to_replace.size
        fail 'fb_storage: Could not map disks to previous ' +
          "ordering: new disks: #{new_disks}, avail slots: " +
          "#{slots_to_replace}."
      end

      if new_disks.size.zero?
        fail 'fb_storage: Found no difference between old' +
          ' and new disks, but somehow didn\'t think they were the same' +
          ' before. Bailing out because I\'m very scared.'
      end
      new_disks.each_with_index do |disk, index|
        slot = slots_to_replace[index]
        new_mapping[slot] = disk
      end

      Chef::Log.info(
        "fb_storage: Previous disk mapping: #{prev}",
      )
      Chef::Log.info(
        "fb_storage: New disk mapping: #{new_mapping}",
      )
      new_mapping
    end

    def self._handle_custom_device_order_method(node)
      if node['fb_storage']['_clowntown_device_order_method'] &&
        (node.firstboot_tier? || File.exist?(FORCE_WRITE_CUSTOM_DISK_ORDER))
        begin
          order = node['fb_storage'][
            '_clowntown_device_order_method'].call
          write_out_disk_order(order)
        ensure
          if File.exist?(FORCE_WRITE_CUSTOM_DISK_ORDER)
            File.delete(FORCE_WRITE_CUSTOM_DISK_ORDER)
          end
        end
      end
    end

    # We need to (consistently) map what's on the box to what's in the config
    # This is the "meat" of what the `storage` API in fb_storage does since
    # it provides a "generic" config.
    def self.sorted_devices(node, maintenance_disks)
      if node['fb_storage']['_ordered_disks']
        return node['fb_storage']['_ordered_disks']
      end

      self._handle_custom_device_order_method(node)

      prev = load_previous_disk_order

      disk_to_slot_mapping = {}
      if node['fb'] && node['fb']['fbjbod']
        unless node['fb']['fbjbod']['shelves'].keys.length.zero?
          shelves = node['fb']['fbjbod']['shelves'].keys.sort
          shelves.each do |shelf|
            node['fb']['fbjbod']['shelves'][shelf].
              each_with_index do |drive, drive_index|
                disk_to_slot_mapping[drive] = {
                  'disk' => drive_index,
                  'shelf' => shelf,
                }
              end
          end
        end
      end
      disk_to_scsi_mapping = {}
      node['scsi']&.each do |id, info|
        disk_to_scsi_mapping[info['device']] = id
      end

      unsorted_devs = Set.new(
        FB::Storage.eligible_devices(node) +
        maintenance_disks.map { |x| ::File.basename(x) },
      )

      # If the set of disks have not changed since last time, use the old
      # order.
      if prev && unsorted_devs == Set.new(prev)
        Chef::Log.debug(
          'fb_storage: Using previous disk ordering from cache',
        )
        node.default['fb_storage']['_ordered_disks'] = prev
        return prev
      end

      devs = unsorted_devs.to_a.sort do |a, b|
        fa = "/dev/#{a}"
        fb = "/dev/#{b}"
        # first and foremost sort drives in a JBOD after ones not in a
        # shelf
        if !disk_to_slot_mapping[fa] && disk_to_slot_mapping[fb]
          Chef::Log.debug(
            "fb_storage: #{a} is not jbod, #{b} is, #{a} sorts first",
          )
          -1
        elsif disk_to_slot_mapping[fa] && !disk_to_slot_mapping[fb]
          # same...
          Chef::Log.debug(
            "fb_storage: #{a} is jbod, #{b} is not, #{b} sorts first",
          )
          1
        elsif disk_to_slot_mapping[fa] && disk_to_slot_mapping[fb]
          # if they're both in a sled, sort by slot number
          Chef::Log.debug(
            "fb_storage: #{a} and #{b} are both jbod " +
              'sorting by slot number',
          )
          sort_disk_shelves(disk_to_slot_mapping[fa],
                            disk_to_slot_mapping[fb])

        else
          # both devices are not on fbjob so we can sort them
          # using our normal sorting algorithm, which will sort by type
          # first, then scsibus if applicable within that, then name
          Chef::Log.debug(
            "fb_storage: #{a} and #{b} are neither jbod " +
              'sorting by length, alphanumeric',
          )
          block_device_sort(fa, fb, disk_to_scsi_mapping)
        end
      end

      if prev
        devs = calculate_updated_order(prev, devs)
      end

      if prev != devs && !devs.empty?
        if can_use_dev_id?(node)
          version = 2
        else
          version = 1
        end
        write_out_disk_order(devs, version)
      end

      node.default['fb_storage']['_ordered_disks'] = devs
      devs
    end

    def self.build_mapping(node, maintenance_disks)
      devs = sorted_devices(node, maintenance_disks)
      # We need to dup this to a real array not the ImmutableArray we get back
      # because we'll make modifications to this copy
      config = node['fb_storage']['devices'].to_a
      num_requested = config.count
      if devs.count > num_requested
        fail "fb_storage: #{num_requested} requested devices, " +
          "which is fewer than available devices #{devs.count} (#{devs}). " +
          'Probably something is wrong. Bailing out!'
      elsif devs.count < num_requested
        fail "fb_storage: Requested #{num_requested} disks but " +
          "only #{devs.count} available. Bailing out!"
      end

      # if we have any storage arrays, prep our datastructure first so
      # when we go through devices we can further fill this out
      #
      # Note since we treat hybrid XFS filesystems like arrays, we will
      # allocate md numbers to them, so if you mix-and-match the two you may
      # not get md numbers starting at 0, but that's not actually a problem.
      desired_arrays = {}
      node['fb_storage']['arrays']&.each_with_index do |cfg, idx|
        desired_arrays["/dev/md#{idx}"] = cfg.to_hash
        desired_arrays["/dev/md#{idx}"]['members'] = []
      end

      desired_disks = {}
      devs.each_with_index do |device, index|
        # AOE devices are a bit special. They come up as "etherd!e1.1" but
        # that maps to "/dev/etherd/e1.1"
        dpath = FB::Storage.device_path_from_name(device)
        Chef::Log.debug(
          "fb_storage: Processing #{dpath}(#{device}): " +
            (config[index]).to_s,
        )
        desired_disks[dpath] = config[index]
        next if config[index]['_skip']

        config[index]['partitions'].each_with_index do |part, pindex|
          pdevice = partition_device_name(
            dpath,
            config[index]['whole_device'] ? '' : pindex + 1,
          )
          if part['_swraid_array']
            array_num = part['_swraid_array']
            desired_arrays["/dev/md#{array_num}"]['members'] << pdevice
          elsif part['_swraid_array_journal']
            array_num = part['_swraid_array_journal']
            desired_arrays["/dev/md#{array_num}"]['journal'] = pdevice
          elsif part['_xfs_rt_data']
            array_num = part['_xfs_rt_data']
            desired_arrays["/dev/md#{array_num}"]['members'] << pdevice
            desired_disks[dpath]['partitions'][pindex]['part_name'] ||=
              desired_arrays["/dev/md#{array_num}"]['mount_point']
          elsif part['_xfs_rt_metadata']
            array_num = part['_xfs_rt_metadata']
            desired_arrays["/dev/md#{array_num}"]['journal'] = pdevice
            desired_disks[dpath]['partitions'][pindex]['part_name'] ||=
              "md:#{desired_arrays["/dev/md#{array_num}"]['mount_point']}"
          elsif part['_xfs_rt_rescue']
            array_num = part['_xfs_rt_rescue']
            # we don't do anything with rescue devices, it's the moral
            # equivalent of _no_mkfs and _no_mount - it's simply
            # saved space for a human to `dd` stuff to ...
            # but we'll go ahead and track it anyway
            desired_arrays["/dev/md#{array_num}"]['rescue'] = pdevice
            desired_disks[dpath]['partitions'][pindex]['part_name'] ||=
              'md_rescue:' +
              desired_arrays["/dev/md#{array_num}"]['mount_point']
          end
        end
      end

      data = { :disks => desired_disks, :arrays => desired_arrays }
      Chef::Log.debug(
        'fb_storage: Disk mapping: ' +
        JSON.pretty_generate(data),
      )
      return data
    end

    # All desired partitions for a given device
    def self.partition_names(device, conf)
      Chef::Log.debug("parition_names: #{device} #{conf}")
      results = []
      conf['partitions'].each_with_index do |_, i|
        results << FB::Storage.partition_device_name(device, i + 1)
      end
      results
    end

    # Take a path like '/dev/nvme0n1p2' or '/dev/sdb1' or '/dev/etherd/e1.1'
    # and return a device name that would show up in node['block_devices']
    # which is mostly just `basename` except in the AOE case...
    def self.device_name_from_path(path)
      File.basename(path.gsub('etherd/', 'etherd!'))
    end

    # Take names like 'nvme0n1pe' or 'sdb1' or 'etherd!e1.1' and return
    # a path. This is mostly just pre-pending /dev/ except in the case of
    # AOE where we need to change '!' into another level of directory
    def self.device_path_from_name(name)
      "/dev/#{name.tr('!', '/')}"
    end

    attr_reader :config, :hotswap_disks, :arrays

    def initialize(node)
      @maintenance_disks = FB::Fstab.get_in_maint_disks
      @hotswap_disks = disks_from_automation
      mapping = build_mapping(node)
      @config = mapping[:disks]
      @arrays = mapping[:arrays]
      # we don't want these changing as we converge...
      @existing = node.filesystem_data.to_hash
      @existing_arrays = node['mdadm'] ? node['mdadm'].to_hash : {}
    end

    def all_storage
      devices = []
      partitions = []
      @config.each do |device, conf|
        next if conf['_skip']

        devices << device
        if conf['whole_device']
          partitions << device
        else
          partitions += partition_names(device, conf)
        end
      end

      valid_arrays = @arrays.reject { |_array, conf| conf['_skip'] }.keys
      {
        :devices => devices,
        # when rebuilding all storage, we need to format the arrays
        # after we build them
        :partitions => partitions + valid_arrays,
        :arrays => valid_arrays,
      }
    end

    def self.get_actual_part_name(part)
      s = Mixlib::ShellOut.new(
        "blkid -o value -s PARTLABEL #{part}",
      ).run_command
      s.error!

      retval = s.stdout.strip

      # we return nil on empty string because part_name in the config is nil
      # when not set
      retval.empty? ? nil : retval
    end

    def get_expected_label_for_hybrid_md_part(part)
      @arrays.each_value do |array|
        if array['journal'] == part
          return array['label']
        end
      end
      return nil
    end

    # Return a list of devices and partitions that are out of spec.
    # Note: this doesn't take into account what we are or are not allowed
    # to touch - it's just what doesn't match the desired state
    def out_of_spec
      @out_of_spec ||= _out_of_spec
    end

    def _out_of_spec
      # a list of devices which have no partition table
      missing_partitions = []
      # a list of devices & partitions which are missing a filesystem
      missing_filesystems = []
      # a list of devices where some parts found when whole_device, or wrong
      # number of parts found. Partition type is not considered.
      mismatched_partitions = []
      # a list of devices & partitions where the observed filesystem type
      # doesn't match the configured
      mismatched_filesystems = []
      # a list of arrays that are missing
      missing_arrays = []
      # arrays that exist but have the wrong members
      mismatched_arrays = []
      # arrays missin gmembers
      incomplete_arrays = {}
      # arrays that we don't have configured
      extra_arrays = []

      @arrays.each do |device, conf|
        short_device = File.basename(device)
        next if conf['_skip'] || conf['raid_level'] == 'hybrid_xfs'

        unless @existing_arrays.include?(short_device)
          Chef::Log.debug(
            "fb_storage: Array #{device} missing",
          )
          missing_arrays << device
          mismatched_filesystems << device
          next
        end

        existing_array = @existing_arrays[short_device]
        existing_device = @existing['by_device'][device]
        existing_members_set = Set.new(
          existing_array['members'].map { |x| "/dev/#{x}" },
        )
        if existing_array['journal']
          existing_members_set += Set.new(
            ["/dev/#{existing_array['journal']}"],
          )
        end
        desired_members_set = Set.new(conf['members'])
        if conf['journal']
          desired_members_set += Set.new([conf['journal']])
        end
        if existing_array['level'] != conf['raid_level']
          Chef::Log.warn(
            "fb_storage: Array #{device} has incorrect raid_level" +
            " #{existing_array['level']} vs #{conf['raid_level']}",
          )
          mismatched_arrays << device
          # and this will require us to nuke the array, so we'll need to
          # make a filesystem too
          mismatched_filesystems << device
        elsif existing_members_set != desired_members_set
          # If the members are not the same, there's two options... we're
          # simply missing members (maybe a disk is in repair)...
          if existing_members_set < desired_members_set
            # Except if it's RAID0, we can't fix that...
            if [existing_array['level'], conf['raid_level']].include?(0)
              Chef::Log.info(
                "fb_storage: Array #{device} is missing members, " +
                'but is RAID0 or should be RAID0 so treating it as a ' +
                'mismatched array.',
              )
              mismatched_arrays << device
              # and this will require us to nuke the array, so we'll need to
              # make a filesystem too
              mismatched_filesystems << device
            else
              missing_members_set = desired_members_set - existing_members_set
              # if the disks are in maintenance, there's nothing to do.
              unless missing_members_set <= Set.new(@maintenance_disks)
                Chef::Log.info(
                  "fb_storage: Array #{device} is missing " +
                  "members: #{missing_members_set.to_a}",
                )
                incomplete_arrays[device] = missing_members_set.to_a
              end
            end
          # or it's made of members we don't expect. In this case, we treat
          # it like a full rebuild
          else
            Chef::Log.warn(
              "fb_storage: Array #{device} has incorrect members" +
              " #{existing_members_set.to_a} vs #{desired_members_set.to_a}",
            )
            mismatched_arrays << device
            # and this will require us to nuke the array, so we'll need to
            # make a filesystem too
            mismatched_filesystems << device
          end
        end

        if !existing_device || !existing_device['fs_type']
          Chef::Log.warn(
            "fb_storage: Array #{device} has no FS",
          )
          missing_filesystems << device
        # We have an existing device *and* it has an FS... compare it
        elsif existing_device['fs_type'] != conf['type']
          current_fs = existing_device ? existing_device['fs_type'] : '(none)'
          Chef::Log.warn(
            "fb_storage: Array #{device} has incorrect FS" +
            " #{current_fs} vs #{conf['type']}",
          )
          mismatched_filesystems << device
        end
      end

      # Find arrays we don't expect
      @existing_arrays.each_key do |shortarray|
        array = "/dev/#{shortarray}"
        next if @arrays[array]

        Chef::Log.info("fb_storage: Extraneous array: #{array}")
        extra_arrays << array
      end

      # now walk our devices config to see what needs convergance
      @config.each do |device, conf|
        if @maintenance_disks.include?(device)
          Chef::Log.info(
            "fb_storage: Skipping check of #{device} because it " +
            'is marked as "in_maintenance"',
          )
          next
        end
        if conf['_skip']
          Chef::Log.info(
            "fb_storage: Skipping check of #{device} because it " +
            'is marked as "skip" in config.',
          )
          next
        end
        devparts = @existing['by_device'].to_hash.keys.select do |x|
          x.start_with?(device) && x != device
        end
        # sort the partitions numerically by partition number
        devparts.sort_by! do |part|
          part.match('\d+$')[0].to_i
        end
        Chef::Log.debug(
          "fb_storage: partitions of #{device} are: #{devparts}",
        )

        dev_info = @existing['by_device'][device]

        if conf['whole_device']
          # there are two ways a whole-device partition can be represented
          # one is no partitions are report... but another is as a "loop"
          # partition type with a single "psuedopartition". In this case
          # the data for the partition in ohai will be an empty hash and the
          # data for the device will have a filesystem.
          has_whole_disk_fs = devparts.count == 1 &&
            @existing['by_device'][devparts[0]].empty? &&
            dev_info['fs_type']
          if devparts.empty? || has_whole_disk_fs
            expected_label = conf['partitions'][0]['label']
            if dev_info.nil? || dev_info.empty?
              Chef::Log.debug(
                "fb_storage: Entire device #{device} needs " +
                'filesystem',
              )
              missing_filesystems << device
            elsif dev_info['fs_type'] != conf['partitions'][0]['type']
              Chef::Log.debug(
                "fb_storage: Entire device #{device} has " +
                'incorrect filesystem',
              )
              mismatched_filesystems << device
            elsif expected_label && dev_info['label'] != expected_label
              mismatched_filesystems << device
              Chef::Log.debug(
                "fb_storage: Entire device #{device} has " +
                "incorrect FS label. Expected #{expected_label}, found " +
                "#{dev_info['label']}.",
              )
            end
          else
            Chef::Log.debug(
              "fb_storage: Device #{device} has partitions " +
              ' but we want a whole-device filesystem',
            )
            # we have a real partition table
            mismatched_partitions << device
            mismatched_filesystems << device
          end
          next
        end

        # if there are no partitions *and* this isn't formatted
        # it's just a missing partition table
        if devparts.empty? && !(dev_info && dev_info['fs_type'])
          Chef::Log.info(
            "fb_storage: #{device} has no partitions and isn't " +
            'formatted',
          )
          missing_partitions << device
          missing_filesystems += partition_names(device, conf)
          next
        end

        # OK, we're here we have partitions and expect to have partitions
        # ... but are they RIGHT?
        if devparts.count != conf['partitions'].count
          Chef::Log.warn(
            "fb_storage: #{device} has the wrong number of " +
            "partitions (#{devparts.count} vs #{conf['partitions'].count})",
          )
          mismatched_partitions << device
          mismatched_filesystems += partition_names(device, conf)
          next
        end

        devparts.each_with_index do |part, index|
          Chef::Log.debug(
            "fb_storage: Considering partition #{part}",
          )
          # We skip member devices of mdraid arrays.
          if conf['partitions'][index]['_swraid_array'] ||
              conf['partitions'][index]['_swraid_array_journal']
            Chef::Log.debug('fb_storage: skipping swraid partition')
            next
          end

          # We need to validate that member devices of hybrid "arrays" have the
          # correct partition labels since the rtxfs helpers depend on this.
          if conf['partitions'][index]['_xfs_rt_data'] ||
              conf['partitions'][index]['_xfs_rt_rescue'] ||
              conf['partitions'][index]['_xfs_rt_metadata']
            expected_part_name = conf['partitions'][index]['part_name']
            actual_part_name = FB::Storage.get_actual_part_name(part)

            if actual_part_name != expected_part_name
              Chef::Log.warn("fb_storage: Partition #{part} expected to " +
                             "have partlabel '#{expected_part_name}', actual " +
                             "is '#{actual_part_name}'.")
              mismatched_partitions << device
            end
          end

          # We skip further validation for hybrid real-time devices since these
          # will not have a filesystem type, label, etc.
          if conf['partitions'][index]['_xfs_rt_data'] ||
              conf['partitions'][index]['_xfs_rt_rescue']
            next
          end

          partinfo = @existing['by_device'][part]
          expected_fs = conf['partitions'][index]['type']
          expected_label = conf['partitions'][index]['label']
          if !expected_label && conf['partitions'][index]['_xfs_rt_metadata']
            # we have to figure out the label that this device corresponds to
            # in the array config
            expected_label = self.get_expected_label_for_hybrid_md_part(part)
          end

          if conf['partitions'][index]['_xfs_rt_metadata']
            expected_fs = 'xfs'
          end

          if !partinfo || !partinfo['fs_type']
            Chef::Log.warn(
              "fb_storage: Partition #{part} has no filesystem",
            )
            missing_filesystems << part
          elsif partinfo['fs_type'] != expected_fs
            Chef::Log.warn(
              "fb_storage: Partition #{part} has the wrong " +
              "filesystem (#{partinfo['fs_type']} vs #{expected_fs})",
            )
            mismatched_filesystems << part
          elsif expected_label && partinfo['label'] != expected_label
            Chef::Log.warn(
              "fb_storage: Partition #{part} has incorrect " +
              "label. Expected #{expected_label}, found " +
              "#{partinfo['label']}.",
            )
            mismatched_filesystems << part
          end
        end
      end

      # Special case for hybrid_xfs
      # For these arrays we don't go through the normal @array loop, because
      # they won't show up in node['mdadm'] - however, we do want to walk
      # the missing FSes on members of hybrid_xfs members, and then push
      # that up to the "array" level so we actually go ahead and create
      # the filesystem
      missing_filesystems.each do |fs|
        mma = @arrays.select do |_array, config|
          config['raid_level'] == 'hybrid_xfs' &&
            (config['members'].include?(fs) ||
             config['journal'] == fs)
        end
        missing_filesystems += mma.keys
      end

      mismatched_filesystems.each do |fs|
        mma = @arrays.select do |_array, config|
          config['raid_level'] == 'hybrid_xfs' &&
            (config['members'].include?(fs) ||
             config['journal'] == fs)
        end
        mismatched_filesystems += mma.keys
      end

      # Done walking @config, put it all together
      {
        :mismatched_partitions => mismatched_partitions.sort.uniq,
        :mismatched_filesystems => mismatched_filesystems.sort.uniq,
        :missing_partitions => missing_partitions.sort.uniq,
        :missing_filesystems => missing_filesystems.sort.uniq,
        :missing_arrays => missing_arrays.sort.uniq,
        :mismatched_arrays => mismatched_arrays.sort.uniq,
        :extra_arrays => extra_arrays.sort.uniq,
        # this one is a hash...
        :incomplete_arrays => incomplete_arrays,
      }
    end

    # Maps the storage config to an fb_fstab config
    def gen_fb_fstab(node)
      use_labels = node['fb_storage']['fstab_use_labels']
      fstab = {}
      fstab_fields =
        %w{type mount_point opts pass enable_remount allow_mount_failure}
      if node['fb_storage']['hybrid_xfs_use_helper']
        node.default['fb_fstab']['type_normalization_map']['rtxfs'] = 'xfs'
        node.default['fb_fstab']['ignorable_opts'] << /^rtdev=.*/
      end
      @config.each do |device, devconf|
        next if devconf['_skip']

        if devconf['whole_device']
          partconf = devconf['partitions'][0]
          if partconf['_swraid_array'] || partconf['_no_mount'] ||
             partconf['_swraid_array_journal']
            next
          end

          name = "storage_#{device}_whole"
          fstab[name] = {
            'device' => use_labels ? "LABEL=#{devconf['label']}" : device,
          }
          fstab_fields.each do |field|
            fstab[name][field] = devconf['partitions'][0][field]
          end
          next
        end
        # rubocop:disable Lint/ShadowingOuterLocalVariable
        devconf['partitions'].each_with_index do |partconf, index|
          # If we are a member of a SW raid array, or we are a member
          # of a hybrid-xfs FS or we've been asked not to mount, then we skip
          # generating the fstab entry.
          if partconf['_no_mount'] ||
             partconf['_swraid_array'] || partconf['_swraid_array_journal'] ||
             partconf['_xfs_rt_data'] || partconf['_xfs_rt_rescue'] ||
             partconf['_xfs_rt_metadata']
            next
          end

          partnum = index + 1
          partition = FB::Storage.partition_device_name(
            device, partnum
          )
          name = "storage_#{partition}"
          fstab[name] = {
            'device' => use_labels ? "LABEL=#{partconf['label']}" : partition,
          }
          fstab_fields.each do |field|
            fstab[name][field] = partconf[field]
          end
        end
        # rubocop:enable Lint/ShadowingOuterLocalVariable
      end
      @arrays.each do |array, arrayconf|
        next if arrayconf['_skip'] || arrayconf['_no_mount']

        name = "storage_#{array}"
        if use_labels
          device = "LABEL=#{arrayconf['label']}"
        elsif arrayconf['raid_level'] == 'hybrid_xfs'
          device = arrayconf['journal']
        else
          device = array
        end
        fstab[name] = {
          'device' => device,
        }
        fstab_fields.each do |field|
          fstab[name][field] = arrayconf[field]
        end
        if arrayconf['raid_level'] == 'hybrid_xfs'
          if node['fb_storage']['hybrid_xfs_use_helper']
            fstab[name]['type'] = 'rtxfs'
          else
            # point the XFS filesystem to it's data device (rtdev)
            fstab[name]['opts'] << ",rtdev=#{arrayconf['members'].first}"
          end
        end
      end
      fstab
    end

    private

    # we make an instance method that calls a class method for easier testing
    # of this method without having to factor out `initialize`.
    def build_mapping(node)
      FB::Storage.build_mapping(node, @maintenance_disks)
    end

    def partition_names(device, conf)
      FB::Storage.partition_names(device, conf)
    end

    def disks_from_automation
      FB::Storage.disks_from_automation
    end
  end
end
