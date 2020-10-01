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
    # Handlers take a given device and know how to partition/format them.
    #
    # The base class may not be used itself, but holds common code most
    # classes will want to use. It also has a class method to build the right
    # object for a given device.
    class Handler
      NO_BASE_CLASS_MSG = 'FB::Storage::Handler is not intended ' +
          'to be instantiated directly, please use a subclass'.freeze
      MDADM = '/sbin/mdadm'.freeze

      # rubocop:disable Style/ClassVars
      @@handler_cache = {}
      def self.get_handler(device, node)
        return @@handler_cache[device] if @@handler_cache[device]

        devname = FB::Storage.device_name_from_path(device)
        if node['block_device'][devname]
          info = node['block_device'][devname].to_hash
        else
          Chef::Log.debug(
            "fb_storage: #{devname} is not in node['block_device']",
          )
          info = {}
        end
        node['fb_storage']['_handlers'].each do |handler|
          unless handler.superclass == FB::Storage::Handler
            fail "fb_storage: handler #{handler.name} is not a subclass of " +
                 'FB::Storage::Handler, aborting!'
          end
          if handler.match?(devname, info)
            Chef::Log.debug("fb_storage: Creating #{handler.name} handler")
            obj = handler.new(device, node)
            @@handler_cache[device] = obj
            return obj
          end
        end

        fail "fb_storage: unknown handler for device #{devname}"
      end
      # rubocop:enable Style/ClassVars

      attr_accessor :mkfs_timeout

      def initialize(device, node)
        if self.class == FB::Storage::Handler
          fail NO_BASE_CLASS_MSG
        end

        @device = device
        @node = node
        @existing_partitions = nil
        self.mkfs_timeout = 600
      end

      # Does the handler work for this device?
      def self.match?(_devname, _info); end

      # Called prior to partitioning
      def prep_device; end

      def wipe_device
        Chef::Log.debug(
          "fb_storage: wipe_device called on #{@device}",
        )
        umount_all_partitions
        remove_all_partitions_from_all_arrays
        existing_partitions.each do |part|
          Chef::Log.info("fb_storage: Deleting #{part}")
          pnum = part.sub(/#{@device}p?/, '')
          cmd = "/sbin/parted -s '#{@device}' rm #{pnum}"
          Chef::Log.debug("fb_storage: running: #{cmd}")
          s = Mixlib::ShellOut.new(cmd).run_command
          if s.error?
            if s.stderr.match(/unrecognised disk label/)
              Chef::Log.debug(
                'fb_storage: Allowing failed removal of ' +
                "#{pnum} from #{@device} as the partition table is " +
                'unrecognised.',
              )
            else
              s.error!
            end
          end
        end
      end

      def partition_device(device_config)
        Chef::Log.info(
          "fb_storage: Writing gpt table to #{@device}",
        )
        Mixlib::ShellOut.new("/sbin/parted -s '#{@device}' mklabel gpt").
          run_command.error!
        return if device_config['whole_device']

        parted_commands = []
        device_config['partitions'].each_with_index do |partinfo, partindex|
          partnum = partindex + 1

          if partinfo['partition_start']
            parted_commands <<
              "mkpart primary #{partinfo['partition_start']} " +
                "#{partinfo['partition_end']} -a optimal " +
                "set #{partnum} boot off"
          else
            parted_commands << 'mkpart primary 0% 100% set 1 boot off'
          end
          if partinfo['_swraid_array'] || partinfo['_swraid_array_journal']
            parted_commands << "set #{partnum} raid on"
          end
          if partinfo['part_name']
            parted_commands << "name #{partnum} #{partinfo['part_name']}"
          end
        end

        Chef::Log.info("fb_storage: Partitioning #{@device}")
        cmd = "/sbin/parted -s '#{@device}' #{parted_commands.join(' ')}"
        Chef::Log.debug("fb_storage: Running #{cmd}")
        Mixlib::ShellOut.new(cmd).run_command.error!
        # wait until a partition shows up
        pname = partition_device_name(1)
        Chef::Log.debug("fb_storage: Polling for #{pname} to exist")
        max_seconds_to_wait = 5
        until File.exist?(pname)
          if max_seconds_to_wait.zero?
            fail 'fb_storage: Made partitions, but partition' +
              " #{pname} never showed up. :("
          end
          Chef::Log.info(
            "fb_storage: Waiting for #{pname} to show up...",
          )
          sleep(1)
          max_seconds_to_wait -= 1
        end
      end

      # Called after partitioning
      def condition_device; end

      # Called before formatting
      def prep_partition(_partition); end

      def format_partition(partition, config)
        # if the whole drive is being converged, this would already have
        # been unmounted, but we could just be converging this partition
        umount_by_partition(partition)
        unless File.basename(partition).start_with?('md')
          Chef::Log.debug(
            'fb_storage: Removing from any relevant arrays',
          )
          remove_device_from_any_arrays(partition)
        end
        cmd = mkfs_cmd(config['type'])
        timeout = self.mkfs_timeout
        unless cmd
          fail "fb_storage: unknown fstype #{config['type']} for " +
            " #{partition}"
        end
        format_options = default_format_options(config['type'])
        if @node['fb_storage']['format_options']
          if @node['fb_storage']['format_options'].is_a?(String)
            format_options =
              @node['fb_storage']['format_options'].dup
          elsif @node['fb_storage']['format_options'].is_a?(Hash)
            format_options =
              @node['fb_storage']['format_options'][config['type']]
          else
            fail "fb_storage: Not sure what to do with 'format_options': " +
              @node['fb_storage']['format_options'].to_s
          end
        end

        device = partition
        if config['raid_level'] == 'hybrid_xfs'
          # If we're hybrid XFS we need to format the metadata device
          # (not the fake 'md' device we have), and also pass in the
          # data device (rtdev)
          device = config['journal']
          extsize = config['extsize'] || 262144 # 256KiB, XFS default

          format_options << ' -d rtinherit=1 -r rtdev=' +
            "#{config['members'].first},extsize=#{extsize}"

          # Realtime is not compatible reflinks.
          # Default for CentOS 8 is crc=1, so let's switch it off here.
          format_options << ' -m crc=0 -m reflink=0'
        end

        label = config['label']
        if config['type'] == 'xfs'
          # XFS sucks and doesn't allow labels longer than 12 chars
          label = label[0..11]
        end
        if config['type'] == 'ext4'
          timeout *= 2
        end
        cmd << " #{format_options} -L \"#{label}\" #{device}"
        Chef::Log.info(
          "fb_storage: Making filesystem on #{device}",
        )
        Chef::Log.debug("fb_storage: Running #{cmd}")
        # In order to make a filesystem on a new md device in a sane
        # amount of time you need to stop the resync first. But that's
        # dangerous if we crash, so we use a begin-ensure here to make sure
        # that we will revert the change before we throw the exception
        limit_file = '/proc/sys/dev/raid/speed_limit_max'
        if @type == :md && config['raid_level'] != 'hybrid_xfs' &&
           File.exist?(limit_file)
          need_to_quiesce_md = true
        else
          need_to_quiesce_md = false
        end
        begin
          if need_to_quiesce_md
            Chef::Log.info(
              'fb_storage: Stopping md resyncing while creating ' +
              'filesystem',
            )
            limit = File.read(limit_file)
            File.write(limit_file, "0\n") # ~FB030
          end

          mkfs = Mixlib::ShellOut.new(cmd, :timeout => timeout)
          mkfs.run_command.error!
        ensure
          if need_to_quiesce_md
            Chef::Log.info(
              'fb_storage: Resuming md resyncing after creating ' +
              'filesystem',
            )
            File.write(limit_file, limit) # ~FB030
          end
        end
      end

      # Called after formatting
      def condition_partition(_partition); end

      def nuke_raid_header(device)
        # Nuke the metadata...
        if File.exist?(device)
          cmd = "#{MDADM} --zero-superblock --force #{device}"
          Chef::Log.debug("fb_storage: Running #{cmd}")
          Mixlib::ShellOut.new(cmd).run_command.error!
          # But it turns out that's not enough... if you don't also
          # nuke the FS header, it'll get auto-mounted if we build an array
          # later, which we're almost certainly about to do
          #
          # ... but don't fail if that dd failed, it may have been
          # smaller than 100MB :)
          cmd = "dd if=/dev/zero of=#{device} bs=1024k count=100"
          Chef::Log.debug("fb_storage: Running #{cmd}")
          Mixlib::ShellOut.new(cmd).run_command
        end
      end

      def array_device_is_in(device)
        return nil unless @node['mdadm']

        @node['mdadm'].each do |array, info|
          Chef::Log.debug(
            "fb_storage: Determining if #{device} is in " +
            array,
          )
          short_dev = ::File.basename(device)
          all_members = info['members'].dup
          all_members << info['journal'] if info['journal']
          all_members += info['spares'] if info['spares']
          if all_members.include?(short_dev)
            Chef::Log.debug(
              "fb_storage: #{device} is in #{array}",
            )
            return "/dev/#{array}"
          end
          Chef::Log.debug(
            "fb_storage: #{device} is NOT in #{array}",
          )
        end
        nil
      end

      # in a separate method so we can mock it in tests
      def _sleep(time)
        sleep(time)
      end

      def remove_device_from_any_arrays(device)
        array = array_device_is_in(device)
        unless array
          Chef::Log.debug(
            "fb_storage: #{device} not found in any arrays",
          )
          return
        end
        unless File.exist?(array)
          Chef::Log.debug(
            "fb_storage: Skipping removing #{device} from " +
            "#{array} because #{array} no longer exists",
          )
          return
        end

        Chef::Log.info(
          "fb_storage: Removing #{device} from #{array}",
        )

        # first we set it faulty
        s = Mixlib::ShellOut.new(
          "#{MDADM} #{array} --fail #{device}",
        ).run_command

        # we need to stop the array and zero the superblock if the error is
        # device or resource busy (and if we are allowed to do so)
        if s.stderr.include?('Device or resource busy') &&
            @node['fb_storage']['stop_and_zero_mdadm_for_format']
          Chef::Log.info("fb_storage: Stopping array #{array}...")
          stop_array(array)
          Chef::Log.info(
            "fb_storage: Zeroing superblock for #{device}...",
          )
          nuke_raid_header(device)
          # we return early from the method here, zeroing superblock removes
          # the device from the array
          return
        else
          s.error!
        end

        # Now, this can take a bit for the drive to quiesce, so we try to
        # remove a few times. It usually only takes ~1s, so we try after
        # a short sleep, and if that doesn't work we try every 10 seconds
        # for one minute
        _sleep(2)

        tries = 0
        max_tries = 6
        interval = 10
        loop do
          s = Mixlib::ShellOut.new(
            "#{MDADM} #{array} --remove #{device}",
          ).run_command

          # if it worked, break
          break unless s.error?

          # If it's any error other than the device being busy, fail.
          unless s.stdout.include?('Device or resource busy')
            s.error!
          end

          # Otherwise, if we'e hit maxtries or it's an error we don't expect,
          # bail out
          if tries == max_tries
            Chef::Log.error(
              "fb_storage: Failed to remove #{device} from " +
              "#{array} after #{max_tries} tries",
            )
            s.error!
          end

          Chef::Log.info(
            "fb_storage: #{device} still busy after setting it " +
            "faulty - sleeping #{interval} seconds and trying again to " +
            'remove it.',
          )

          # otherwise sleep for $interval seconds and try again
          _sleep(interval)
          tries += 1
        end
      end

      def remove_from_arrays(devices)
        devices.each do |device|
          remove_device_from_any_arrays(device)
        end
      end

      # When we're not an array, nuke anything holding us
      def remove_all_partitions_from_all_arrays
        list = existing_partitions + [@device]
        Chef::Log.debug(
          'fb_storage: Removing all partitions from all arrays ' +
          "that contain any of #{list}",
        )
        affected = remove_from_arrays(list)
        affected.each { |d| nuke_raid_header(d) }
      end

      def stop_array(array)
        if File.exist?(array)
          Chef::Log.info("fb_storage: Stopping array: #{array}")
          cmd = "#{MDADM} -S #{array}"
          Mixlib::ShellOut.new(cmd).run_command.error!
        else
          Chef::Log.debug(
            "fb_storage: Skipping request to stop #{array} " +
            'because it no longer exists',
          )
        end
      end

      def umount_all_partitions
        existing_partitions.each do |part|
          umount_by_partition(part)
        end
        umount_device
      end

      def umount_by_partition(partition)
        # the 'mounts' check should be all that's necessary - unless we
        # partitioned this device in this run :)
        if @node.filesystem_data['by_device'][partition] &&
           @node.filesystem_data['by_device'][partition]['mounts']
          @node.filesystem_data['by_device'][partition]['mounts'].each do |m|
            umount(m)
          end
        end
      end

      def umount_device
        if @node.filesystem_data['by_device'][@device] &&
            @node.filesystem_data['by_device'][@device]['mounts']
          @node.filesystem_data['by_device'][@device]['mounts'].each do |m|
            umount(m)
          end
        end
      end

      def umount(m)
        # we may call umount on the same thing more than once depending on
        # our path through the system, so check it's actually mounted.
        if Pathname.new(m).mountpoint?
          Chef::Log.info("fb_storage: Unmounting #{m}")
          Mixlib::ShellOut.new("/bin/umount #{m}").run_command.error!
        end
      end

      def partition_device_name(num)
        FB::Storage.partition_device_name(@device, num)
      end

      def existing_partitions
        @existing_partitions ||=
          @node.filesystem_data['by_device'].keys.select do |x|
            x.start_with?(@device) && x != @device
          end
      end

      def mkfs_cmd(type)
        case type
        when 'xfs'
          'mkfs -t xfs -f'
        when 'btrfs'
          'mkfs.btrfs -f'
        when 'ext4', 'ext3', 'ext2'
          "mkfs -t #{type} -F"
        end
      end

      def default_format_options(type)
        case type
        when 'xfs'
          '-i size=2048'
        when 'btrfs'
          '-l 16K -n 16K'
        when 'ext4'
          ''
        end
      end

      class FioHandler < FB::Storage::Handler
        def initialize(device, node)
          super
          @type = :fio
          raw = device.sub('fio', 'fct')
          num = raw[-1].tr('[a-j]', '[0-9]')
          raw[-1] = num
          @raw_device = raw
        end

        def self.match?(devname, _info)
          devname.start_with?('fio')
        end

        def prep_device
          # "format" isn't "make a filesystem" but some other magical
          # flash prep thing
          { 'detach' => nil,
            'format' => '-y',
            'attach' => nil }.each do |step, opts|
            cmd = "/usr/bin/fio-#{step}"
            cmd << " #{opts}" if opts
            Chef::Log.debug(
              "fb_storage: Running #{cmd} #{@raw_device}",
            )
            Mixlib::ShellOut.new("#{cmd} #{@raw_device}").
              run_command.error!
          end
        end
      end

      class JbodHandler < FB::Storage::Handler
        def initialize(device, node)
          super
          @type = :jbod
          # Current AOE drivers have a bug where big partitions can take
          # more than 10 minutes to run mkfs
          self.mkfs_timeout = 900
        end

        # JBOD always matches as it'll work for every block device
        def self.match?(_devname, _info)
          true
        end
      end

      class MdHandler < FB::Storage::Handler
        def initialize(device, node)
          super
          @type = :md
        end

        def self.match?(devname, _info)
          devname.start_with?('md')
        end

        def default_format_options(type)
          opts = super(type)
          if type == 'xfs'
            # there's no need to discard blocks on md devices
            opts << ' -K'
          end
          opts
        end

        def build(config)
          Chef::Log.info(
            "fb_storage: Creating array: #{@device}",
          )
          Chef::Log.debug(
            "fb_storage: ... out of #{config['members']}",
          )
          # We set homehost to `any` since many of our hostnames won't fit
          # in the md superblock's name field, and that causes the hostname
          # not to match and the device to end up as md127.
          #
          # It's also worth noting that we don't use --name, which despite
          # earlier code's implication, is actually the field that holds
          # "$NAME:$INDEX" (related to homehost above), so we don't set it
          # statically and mdadm will set it to "any:$INDEX" when we specify
          # --homehost=any
          cmd = "echo y | #{MDADM} --create #{@device} --force " +
            "--homehost=any --raid-devices=#{config['members'].length} " +
            "--level=#{config['raid_level']}"
          if config['raid_stripe_size']
            cmd << " --chunk #{config['raid_stripe_size']}"
          end
          if config['journal']
            cmd << " --write-journal #{config['journal']}"
          end
          if config['create_options']
            cmd << " #{config['create_options']}"
          end
          cmd << " #{config['members'].join(' ')}"

          Mixlib::ShellOut.new(cmd).run_command.error!
          Mixlib::ShellOut.new("udevadm trigger #{@device}").run_command.error!
        end

        def stop
          umount_by_partition(@device)
          stop_array(@device)
        end

        def wipe_member_devices(config)
          config['members'].each do |device|
            Chef::Log.info(
              "fb_storage: Wiping out #{device}",
            )
            umount_by_partition(device)
            nuke_raid_header(device)
          end
        end
      end
    end
  end
end
