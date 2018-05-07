# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

module FB
  # Module to be loaded into the provider namespace
  module FstabProvider
    def mount(mount_data, in_maint_disks)
      relevant_disk = nil
      if in_maint_disks.any? do |disk|
        if mount_data['device'].start_with?(disk)
          relevant_disk = disk
          next true
        end
      end
        Chef::Log.warn(
          "fb_fstab: Skipping mount of #{mount_data['mount_point']} because " +
          " device #{relevant_disk} is marked as in-maintenance",
        )
        return true
      end
      # We don't use a 'directory' resource, because that would happen
      # later. Also, we don't want to conflict with resources that may
      # actually managed this directory (though they better check it's
      # not mounted :)). We just make sure there's a safe directory
      # to mount to before we call 'mount'
      #
      # Further, because we're called in a 'converge' block, this is whyrun
      # safe, just like the Mixlib::ShellOut below.
      Chef::Log.info("fb_fstab: Mounting #{mount_data['mount_point']}")
      if ::File.exist?(mount_data['mount_point'])
        if ::File.symlink?(mount_data['mount_point'])
          if mount_data['allow_mount_failure']
            msg = "fb_fstab: #{mount_data['mount_point']} is a symlink. " +
                  'This is probably not what you want and could cause SEVs.'
            Chef::Log.warn(msg)
            return false
          else
            fail "fb_fstab: #{mount_data['mount_point']} is a symlink, thus" +
              ' I will not mount over it.'
          end
        end
      else
        # we pass in a relatively sane perm which is subject to umask If they
        # sent in perms, we'll do a real chmod right afterward which isn't
        # subject to umask.
        FileUtils.mkdir_p(mount_data['mount_point'], :mode => 0o755)
        if mount_data['mp_perms']
          FileUtils.chmod(mount_data['mp_perms'].to_i(8),
                          mount_data['mount_point'])
        end
        if mount_data['mp_owner'] || mount_data['mp_group']
          FileUtils.chown(mount_data['mp_owner'], mount_data['mp_group'],
                          mount_data['mount_point'])
        end
      end
      if node.systemd?
        # If you use FUSE mounts, and you're running Chef from a systemd timer,
        # the FUSE helpers will be killed after a chef run, which unmounts your
        # filesystem, which is clearly not what you want. So we instead want to
        # ask systemd to do the mount for us. The cleanest way to do that is to
        # ask systemd what it's generated unit for that mount is and then
        # "start" that unit.
        #
        # HOWEVER!!!! NOTE WELL!!!!
        # If you don't do a `systemctl daemon-reload` after updating /etc/fstab,
        # then this won't be gauranteed to mount the right thing, so we have
        # that notify in the recipe
        s = Mixlib::ShellOut.new(
          "/bin/systemd-escape -p --suffix=mount #{mount_data['mount_point']}",
        ).run_command
        s.error!
        mountunit = s.stdout.chomp.shellescape
        s = Mixlib::ShellOut.new("/bin/systemctl start #{mountunit}")
      else
        # We cd into /dev/shm because otherwise mount will be dumb and
        # change the device of 'foo' to be '/foo' if /foo happens to exist.
        #
        # I COULD call --no-canonicalize except that when /bin/mount calls
        # /sbin/mount.tmpfs, it won't preserve that option, and then calls
        # /bin/mount -i without it and it's canonicalized anyway. Further on
        # other FS's --no-canonicalize may not be safe. THUS, we cd to a place
        # that should be emptyish.
        s = Mixlib::ShellOut.new(
          "cd /dev/shm && /bin/mount #{mount_data['mount_point']}",
        )
      end

      _run_command_flocked(s,
                           mount_data['lock_file'],
                           mount_data['mount_point'])
      if s.error? && mount_data['allow_mount_failure']
        Chef::Log.warn(
          "fb_fstab: Mounting #{mount_data['mount_point']} failed, but " +
          '"allow_mount_failure" was set, so moving on.',
        )
      else
        s.error!
      end
      true
    end

    def umount(mount_point, lock_file)
      Chef::Log.info("fb_fstab: Unmounting #{mount_point}")
      s = Mixlib::ShellOut.new("/bin/umount #{mount_point}")
      _run_command_flocked(s, lock_file, mount_point)
      if s.error? && node['fb_fstab']['allow_lazy_umount']
        Chef::Log.warn("fb_fstab: #{s.stderr.chomp}")
        Chef::Log.warn(
          "fb_fstab: Unmounting #{mount_point} failed, " +
          'trying lazy unmount.',
        )
        sl = Mixlib::ShellOut.new("/bin/umount -l #{mount_point}")
        _run_command_flocked(sl, lock_file, mount_point)
      else
        s.error!
      end
      true
    end

    def remount(mount_point, with_umount, lock_file)
      Chef::Log.info("fb_fstab: Remounting #{mount_point}")
      if with_umount
        Chef::Log.debug("fb_fstab: umount and mounting #{mount_point}")
        cmd = "/bin/umount #{mount_point}; /bin/mount #{mount_point}"
      else
        Chef::Log.debug("fb_fstab: 'mount -o remount' on #{mount_point}")
        cmd = "/bin/mount -o remount #{mount_point}"
      end
      s = Mixlib::ShellOut.new(cmd)
      _run_command_flocked(s, lock_file, mount_point)
      s.error!
    end

    def get_unmasked_base_mounts(format)
      FB::Fstab.get_unmasked_base_mounts(format, node)
    end

    def canonicalize_device(device)
      FB::Fstab.canonicalize_device(device, node)
    end

    # Given a *mounted* device from node['filesystem2'] in `mounted_data`, check
    # to see if we want to keep it. It looks in `desired_mounts` (an export of
    # node['fb_fstab']['mounts'] as well as `base_mounts` (a hash
    # representation of the saved OS mounts file).
    def should_keep(mounted_data, desired_mounts, base_mounts)
      Chef::Log.debug(
        "fb_fstab: Should we keep #{mounted_data}?",
      )
      # Does it look like something in desired mounts?
      desired_mounts.each_value do |desired_data|
        begin
          desired_device = canonicalize_device(desired_data['device'])
        rescue RuntimeError
          next if desired_data['allow_mount_failure']
          raise
        end
        Chef::Log.debug("fb_fstab: --> Lets see if it matches #{desired_data}")
        # if the devices are the same *and* are real devices, the
        # rest doesn't matter - we won't unmount a moved device. moves
        # option changes, etc. are all the work of the 'mount' step later.
        if mounted_data['device'] && mounted_data['device'].start_with?('/dev/')
          if desired_device == mounted_data['device']
            Chef::Log.debug(
              "fb_fstab: Device #{mounted_data['device']} is supposed to be " +
              ' mounted, not considering for unmount',
            )
            return true
          end
        # If it's a virtual device, we just check the type and mount
        # point are the same
        elsif desired_data['mount_point'] == mounted_data['mount'] &&
              compare_fstype(desired_data['type'], mounted_data['fs_type'])
          Chef::Log.debug(
            "fb_fstab: Virtual fs of type #{mounted_data['fs_type']} is " +
            "desired at #{mounted_data['mount']}, not considering for unmount",
          )
          return true
        end
        Chef::Log.debug('fb_fstab: --> ... nope')
      end

      # If not, is it autofs controlled?
      if FB::Fstab.autofs_parent(mounted_data['mount'], node)
        Chef::Log.debug(
          "fb_fstab: #{mounted_data['device']} (#{mounted_data['mount']}) is" +
          ' autofs-controlled.',
        )
        return true
      end

      # If not, is it a base mount?
      # Note that if it's not in desired mounts, we can be more strict,
      # no one is trying to move things... it should be same device and point.
      Chef::Log.debug('fb_fstab: --> OK, well is it a base mount?')
      if base_mounts[mounted_data['device']] &&
         base_mounts[mounted_data['device']]['mount_point'] ==
         mounted_data['mount']
        Chef::Log.debug(
          "fb_fstab: #{mounted_data['device']} on #{mounted_data['mount']} is" +
          ' a base mount, not considering for unmount',
        )
        return true
      end
      false
    end

    # Walk all mounted filesystems and umount anything we don't know about
    def check_unwanted_filesystems
      # extra things to skip
      devs_to_skip = node['fb_fstab']['umount_ignores']['devices'].dup
      dev_prefixes_to_skip =
        node['fb_fstab']['umount_ignores']['device_prefixes'].dup
      mounts_to_skip =
        node['fb_fstab']['umount_ignores']['mount_points'].dup
      mount_prefixes_to_skip =
        node['fb_fstab']['umount_ignores']['mount_point_prefixes'].dup
      fstypes_to_skip = node['fb_fstab']['umount_ignores']['types'].dup

      base_mounts = get_unmasked_base_mounts(:hash)

      # we're going to iterate over specified mounts a lot, lets dump it
      desired_mounts = node['fb_fstab']['mounts'].to_hash

      node['filesystem2']['by_pair'].to_hash.each_value do |mounted_data|
        # ohai uses many things to populate this structure, one of which
        # is 'blkid' which gives info on devices that are not currently
        # mounted. This skips those, plus swap, of course.
        unless mounted_data['mount']
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "- it isn't mounted.",
          )
          next
        end
        # Work around chef 12 ohai bug
        if mounted_data.key?('inodes_used') && !mounted_data.key?('kb_used')
          Chef::Log.debug(
            'fb_fstab: Skipping mal-formed Chef 12 "df -i" entry ' +
            mounted_data.to_s,
          )
          next
        end
        # skip anything seemingly magical
        if devs_to_skip.include?(mounted_data['device'])
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "(#{mounted_data['mount']}): exempted device",
          )
          next
        elsif mounts_to_skip.include?(mounted_data['mount'])
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "(#{mounted_data['mount']}): exempted mountpoint",
          )
          next
        elsif fstypes_to_skip.include?(mounted_data['fs_type'])
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "(#{mounted_data['mount']}): exempted fstype",
          )
          next
        elsif dev_prefixes_to_skip.any? do |i|
          mounted_data['device'] && mounted_data['device'].start_with?(i)
        end
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "(#{mounted_data['mount']}) - exempted device prefix",
          )
          next
        elsif mount_prefixes_to_skip.any? do |i|
          mounted_data['mount'] && mounted_data['mount'].start_with?(i)
        end
          Chef::Log.debug(
            "fb_fstab: Skipping umount check for #{mounted_data['device']} " +
            "(#{mounted_data['mount']}) - exempted mount_point prefix",
          )
          next
        end

        # Is this device in our list of desired mounts?
        next if should_keep(mounted_data, desired_mounts, base_mounts)

        if node['fb_fstab']['enable_unmount']
          converge_by "unmount #{mounted_data['mount']}" do
            umount(mounted_data['mount'], mounted_data['lock_file'])
          end
        else
          Chef::Log.warn(
            "fb_fstab: Would umount #{mounted_data['device']} from " +
            "#{mounted_data['mount']}, but " +
            'node["fb_fstab"]["enable_unmount"] is false',
          )
          Chef::Log.debug("fb_fstab: #{mounted_data}")
        end
      end
    end

    def _normalize_type(type)
      if node['fb_fstab']['type_normalization_map'][type]
        return node['fb_fstab']['type_normalization_map'][type]
      end
      type
    end

    # We consider a filesystem type the "same" if they are identical or if
    # one is auto.
    def compare_fstype(type1, type2)
      type1 == type2 || _normalize_type(type1) == _normalize_type(type2)
    end

    def delete_ignored_opts!(tlist)
      ignorable_opts_s = node['fb_fstab']['ignorable_opts'].select do |x|
        x.is_a?(::String)
      end
      ignorable_opts_r = node['fb_fstab']['ignorable_opts'].select do |x|
        x.is_a?(::Regexp)
      end
      tlist.delete_if do |x|
        ignorable_opts_s.include?(x) ||
          ignorable_opts_r.any? do |regex|
            x =~ regex
          end
      end
    end

    # This translates human-readable size mount options into their
    # canonical bytes form. I.e. "size=4G" into "size=4194304"
    #
    # Assumes it's really a size opt - validate before calling!
    def translate_size_opt(opt)
      val = opt.split('=').last
      mag = val[-1].downcase
      mags = ['k', 'm', 'g', 't']
      return opt unless mags.include?(mag)
      num = val[0..-2].to_i
      mags.each do |d|
        num *= 1024
        return "size=#{num}" if mag == d
      end
      fail RangeError "fb_fstab: Failed to translate #{opt}"
    end

    def canonicalize_opts(opts)
      # ensure both are arrays
      optsl = opts.is_a?(Array) ? opts.dup : opts.split(',')
      # 'rw' is implied, so if no readability is specified, add it to both,
      # so missing on one if them doesn't cause a false-negative
      optsl << 'rw' unless optsl.include?('ro') || optsl.include?('rw')
      delete_ignored_opts!(optsl)
      optsl.map! do |x|
        x.start_with?('size=') ? translate_size_opt(x) : x
      end

      # sort
      optsl.sort
    end

    # Take opts in a variety of forms, and compare them intelligently
    def compare_opts(opts1, opts2)
      c1 = canonicalize_opts(opts1)
      c2 = canonicalize_opts(opts2)

      # Check that they're the same
      c1 == c2
    end

    # Given a tmpfs desired mount `desired` check to see what it's status is;
    # mounted (:same), needs remount (:remount), not mounted (:missing) or
    # something else is mounted in the way (:conflict)
    #
    # This is roughly the same as mount_status() below but we make many
    # exceptions for tmpfs filesystems.
    #
    # Unlike mount_status() we will never return :moved since there's no unique
    # device to move.
    def tmpfs_mount_status(desired)
      # Start with checking if it was mounted the way we would mount it
      # this is ALMOST the same as the 'is it identical' check for non-tmpfs
      # filesystems except that with tmpfs we don't treat 'auto' as equivalent
      key = "#{desired['device']},#{desired['mount_point']}"
      if node['filesystem2']['by_pair'][key]
        mounted = node['filesystem2']['by_pair'][key].to_hash
        if mounted['fs_type'] == 'tmpfs'
          Chef::Log.debug(
            "fb_fstab: tmpfs #{desired['device']} on " +
            "#{desired['mount_point']} is currently mounted...",
          )
          if compare_opts(desired['opts'], mounted['mount_options'])
            Chef::Log.debug('fb_fstab: ... with identical options.')
            return :same
          else
            Chef::Log.debug(
              "fb_fstab: ... with different options #{desired['opts']} vs " +
              mounted['mount_options'].join(','),
            )
            Chef::Log.info(
              "fb_fstab: #{desired['mount_point']} is mounted with options " +
              "#{canonicalize_opts(mounted['mount_options'])} instead of " +
              canonicalize_opts(desired['opts']).to_s,
            )
            return :remount
          end
        end
      end
      # OK, if that's not the case, we don't have the same device, which
      # is OK. Find out if we have something mounted at the same spot, and
      # get its device name so we can find it's entry in node['filesystem2']
      if node['filesystem2']['by_mountpoint'][desired['mount_point']]
        # If we are here the mountpoints are the same...
        mounted =
          node['filesystem2']['by_mountpoint'][desired['mount_point']].to_hash
        # OK, if it's tmpfs as well, we're diong good
        if mounted['fs_type'] == 'tmpfs'
          Chef::Log.warn(
            "fb_fstab: Treating #{mounted['devices']} on " +
            "#{desired['mount_point']} the same as #{desired['device']} on " +
            "#{desired['mount_point']} because they are both tmpfs.",
          )
          Chef::Log.debug(
            "fb_fstab: tmpfs #{desired['device']} on " +
            "#{desired['mount_point']} is currently mounted...",
          )
          Chef::Log.debug("fb_fstab: #{desired} vs #{mounted}")
          if compare_opts(desired['opts'], mounted['mount_options'])
            Chef::Log.debug('fb_fstab: ... with identical options.')
            return :same
          else
            Chef::Log.debug(
              "fb_fstab: ... with different options #{desired['opts']} vs " +
              mounted['mount_options'].join(','),
            )
            Chef::Log.info(
              "fb_fstab: #{desired['mount_point']} is mounted with options " +
              "#{canonicalize_opts(mounted['mount_options'])} instead of " +
              canonicalize_opts(desired['opts']).to_s,
            )
            return :remount
          end
        end
        Chef::Log.warn(
          "fb_fstab: tmpfs is desired on #{desired['mount_point']}, but " +
          "non-tmpfs #{mounted['devices']} (#{mounted['fs_type']}) currently " +
          'mounted there.',
        )
        return :conflict
      end
      return :missing
    end

    # Given a desired mount `desired` check to see what it's status is;
    # mounted (:same), needs remount (:remount), not mounted (:missing),
    # moved (:moved), or something else is mounted in the way (:conflict)
    def mount_status(desired)
      # We treat tmpfs specially. While we don't want people to mount tmpfs with
      # a device of 'none' or 'tmpfs', we also don't want to make them remount
      # (and lose all their data) just to convert to fb_fstab. So we'll make
      # them use a new name in the config, but we will treat the pre-mounted
      # mounts as valid/the same. Besides, since the device is meaningless, we
      # can just ignore it for the purposes of this test anyway.
      if desired['type'] == 'tmpfs'
        return tmpfs_mount_status(desired)
      end

      key = "#{desired['device']},#{desired['mount_point']}"
      mounted = nil
      if node['filesystem2']['by_pair'][key]
        mounted = node['filesystem2']['by_pair'][key].to_hash
      else
        key = "#{desired['device']}/,#{desired['mount_point']}"
        if node['filesystem2']['by_pair'][key]
          mounted = node['filesystem2']['by_pair'][key].to_hash
        end
      end

      if mounted
        Chef::Log.debug(
          "fb_fstab: There is an entry in node['filesystem2'] for #{key}",
        )
        # If it's a virtual device, we require the fs type to be identical.
        # otherwise, we require them to be similar. This is because 'auto'
        # is meaningless without a physical device, so we don't want to allow
        # it to be the same.
        if compare_fstype(desired['type'], mounted['fs_type']) ||
           (desired['device'].start_with?('/') &&
            [desired['type'], mounted['fs_type']].include?('auto'))
          Chef::Log.debug(
            "fb_fstab: FS #{desired['device']} on #{desired['mount_point']}" +
            ' is currently mounted...',
          )
          if compare_opts(desired['opts'], mounted['mount_options'])
            Chef::Log.debug('fb_fstab: ... with identical options.')
            return :same
          else
            Chef::Log.debug(
              "fb_fstab: ... with different options #{desired['opts']} vs " +
              mounted['mount_options'].join(','),
            )
            Chef::Log.info(
              "fb_fstab: #{desired['mount_point']} is mounted with options " +
              "#{canonicalize_opts(mounted['mount_options'])} instead of " +
              canonicalize_opts(desired['opts']).to_s,
            )
            return :remount
          end
        else
          Chef::Log.warn(
            "fb_fstab: Device #{desired['device']} is mounted at " +
            "#{mounted['mount']} as desired, but with fstype " +
            "#{mounted['fs_type']} instead of #{desired['type']}",
          )
          return :conflict
        end
      end

      # In this case we don't have the device we expect at the mountpoint we
      # expect. Assuming it's not NFS/Gluster which can be mounted in more than
      # once place, we look up this device and see if it moved or just isn't
      # mounted
      unless ['nfs', 'glusterfs'].include?(desired['type'])
        device = node['filesystem2']['by_device'][desired['device']]
        if device && device['mounts'] && !device['mounts'].empty?
          Chef::Log.warn(
            "fb_fstab: #{desired['device']} is at #{device['mounts']}, but" +
            " we want it at #{desired['mount_point']}",
          )
          return :moved
        end
      end

      # Ok, this device isn't mounted, but before we return we need to check
      # if anything else is mounted where we want to be.
      if node['filesystem2']['by_mountpoint'][desired['mount_point']]
        devices = node['filesystem2']['by_mountpoint'][
            desired['mount_point']]['devices']
        Chef::Log.warn(
          "fb_fstab: Device #{desired['device']} desired at " +
          "#{desired['mount_point']} but something #{devices} already " +
          'mounted there.',
        )
        return :conflict
      end
      :missing
    end

    def check_wanted_filesystems
      # before we do anything... node['filesystem2'] is a mapping of devices
      # to mountpoint, but that won't work for things with a device of "none",
      # so build a reverse mapping too
      in_maint_disks = FB::Fstab.get_in_maint_disks

      # walk desired mounts, see if it's mounted, and mount/update
      # as appropriate.
      node['fb_fstab']['mounts'].to_hash.each_value do |desired_data|
        # Using "none" as a device is deprecated. You can use descriptive
        # strings now. Doing so is not only the new hotness, but it also
        # prevents dupes in node['filesystem2'] - so we require it.
        if desired_data['device'] == 'none'
          Chef::Log.warn('fb_fstab: We do not permit "none" devices, please ' +
                          'use a descriptive device name')
          next
        end

        if desired_data['type'] == 'swap'
          Chef::Log.debug('fb_fstab: We do not change swap from fb_fstab, ' +
                          'moving on...')
          next
        end

        begin
          desired_data['device'] = canonicalize_device(desired_data['device'])
        rescue RuntimeError
          next if desired_data['allow_mount_failure']
        end

        status = mount_status(desired_data)

        case status
        when :same
          Chef::Log.debug(
            "fb_fstab: Skipping #{desired_data['mount_point']}; looks good!",
          )
          next
        when :missing
          converge_by "mount #{desired_data['mount_point']}" do
            mount(desired_data, in_maint_disks)
          end
          # Device mounted, move on...
          next
        when :conflict
          # We already threw a warning, just note we're moving on
          Chef::Log.info(
            "fb_fstab: Skipping #{desired_data['mount_point']} due to conflict",
          )
          next
        when :moved
          Chef::Log.info(
            "fb_fstab: Skipping #{desired_data['mount_point']} since it " +
            'moved. Moving filesystems is scary.',
          )
          next
        when :remount
          base_msg = "fb_fstab: Mountpoint #{desired_data['mount_point']} " +
                     'options changed'
          if node['fb_fstab']['enable_remount'] &&
             desired_data['enable_remount']
            Chef::Log.debug("fb_fstab: #{base_msg} - remounting")
            converge_by "remount #{desired_data['mount_point']}" do
              remount(desired_data['mount_point'],
                      desired_data['remount_with_umount'],
                      desired_data['lock_file'])
            end
            # There's nothing after us in the loop at this point, but I'm being
            # explicit with the 'next' here so that we never accidentally
            # remount an FS twice
            next
          else
            Chef::Log.warn("#{base_msg}, but remounts are not enabled")
          end
        end
      end
    end

    def _run_command_flocked(shellout, lock_file, mount_point)
      if lock_file.nil?
        return shellout.run_command
      else
        lock_fd = File.open(lock_file, 'a+')
        unless lock_fd.flock(File::LOCK_EX | File::LOCK_NB)
          fail IOError, "Couldn't grab lock at #{lock_file} for #{mount_point}"
        end

        begin
          return shellout.run_command
        ensure
          lock_fd.flock(File::LOCK_UN)
        end
      end
    end
  end
end
