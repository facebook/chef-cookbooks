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
#

class Chef
  # Our extensions of the node object
  class Node
    def centos?
      self['platform'] == 'centos'
    end

    def centos9?
      self.centos? && self['platform_version'].start_with?('9')
    end

    def centos8?
      self.centos? && self['platform_version'].start_with?('8')
    end

    def centos7?
      self.centos? && self['platform_version'].start_with?('7')
    end

    def centos6?
      self.centos? && self['platform_version'].start_with?('6')
    end

    def centos5?
      self.centos? && self['platform_version'].start_with?('5')
    end

    def major_platform_version
      self['platform_version'].split('.')[0]
    end

    def fedora?
      self['platform'] == 'fedora'
    end

    def fedora27?
      self.fedora? && self['platform_version'] == '27'
    end

    def fedora28?
      self.fedora? && self['platform_version'] == '28'
    end

    def fedora29?
      self.fedora? && self['platform_version'] == '29'
    end

    def fedora30?
      self.fedora? && self['platform_version'] == '30'
    end

    def fedora31?
      self.fedora? && self['platform_version'] == '31'
    end

    def fedora32?
      self.fedora? && self['platform_version'] == '32'
    end

    def fedora33?
      self.fedora? && self['platform_version'] == '33'
    end

    def fedora34?
      self.fedora? && self['platform_version'] == '34'
    end

    def fedora35?
      self.fedora? && self['platform_version'] == '35'
    end

    def redhat?
      self['platform'] == 'redhat'
    end

    def redhat6?
      self.redhat? && self['platform_version'].start_with?('6')
    end

    def redhat7?
      self.redhat? && self['platform_version'].start_with?('7')
    end

    def redhat8?
      self.redhat? && self['platform_version'].start_with?('8')
    end

    def redhat9?
      self.redhat? && self['platform_version'].start_with?('9')
    end

    def rhel?
      self['platform_family'] == 'rhel'
    end

    def rhel7?
      self.rhel? && self['platform_version'].start_with?('7')
    end

    def rhel8?
      self.rhel? && self['platform_version'].start_with?('8')
    end

    def rhel9?
      self.rhel? && self['platform_version'].start_with?('9')
    end

    def oracle?
      self['platform'] == 'oracle'
    end

    def oracle8?
      self.oracle? && self['platform_version'].start_with?('8')
    end

    def oracle7?
      self.oracle? && self['platform_version'].start_with?('7')
    end

    def oracle6?
      self.oracle? && self['platform_version'].start_with?('6')
    end

    def oracle5?
      self.oracle? && self['platform_version'].start_with?('5')
    end

    def debian?
      self['platform'] == 'debian'
    end

    def debian_sid?
      debian? && self['platform_version'].include?('sid')
    end

    def ubuntu?
      self['platform'] == 'ubuntu'
    end

    def ubuntu12?
      ubuntu? && self['platform_version'].start_with?('12')
    end

    def ubuntu14?
      ubuntu? && self['platform_version'].start_with?('14.')
    end

    def ubuntu15?
      ubuntu? && self['platform_version'].start_with?('15.')
    end

    def ubuntu16?
      ubuntu? && self['platform_version'].start_with?('16.')
    end

    def ubuntu1610?
      ubuntu? && self['platform_version'] == '16.10'
    end

    def ubuntu17?
      ubuntu? && self['platform_version'].start_with?('17')
    end

    def ubuntu1704?
      ubuntu? && self['platform_version'] == '17.04'
    end

    def ubuntu18?
      ubuntu? && self['platform_version'].start_with?('18.')
    end

    def ubuntu1804?
      ubuntu? && self['platform_version'] == '18.04'
    end

    def ubuntu20?
      ubuntu? && self['platform_version'].start_with?('20.')
    end

    def linuxmint?
      self['platform'] == 'linuxmint'
    end

    def linux?
      self['os'] == 'linux'
    end

    def arch?
      self['platform'] == 'arch'
    end

    def debian_family?
      self['platform_family'] == 'debian'
    end

    def arch_family?
      self['platform_family'] == 'arch'
    end

    def fedora_family?
      self['platform_family'] == 'fedora'
    end

    def macos?
      %w{mac_os_x macos}.include?(self['platform'])
    rescue StandardError
      RUBY_PLATFORM.include?('darwin')
    end

    alias macosx? macos?

    def macos10?
      macos? && node['platform_version'].start_with?('10.')
    end

    def macos11?
      macos? && node['platform_version'].start_with?('11.')
    end

    def macos12?
      macos? && node['platform_version'].start_with?('12.')
    end

    def mac_mini_2014?
      macos? && node['hardware']['machine_model'] == 'Macmini7,1'
    end

    def mac_mini_2018?
      macos? && node['hardware']['machine_model'] == 'Macmini8,1'
    end

    def mac_mini_2020?
      macos? && node['hardware']['machine_model'] == 'Macmini9,1'
    end

    def windows?
      self['platform_family'] == 'windows'
    end

    def windows8?
      windows? && self['platform_version'].start_with?('6.2')
    end

    def windows8_1?
      windows? && self['platform_version'].start_with?('6.3')
    end

    def windows10?
      windows? && self['platform_version'].start_with?('10.0')
    end

    def windows2008?
      windows? && self['platform_version'] == '6.0'
    end

    def windows2008r2?
      windows? && self['platform_version'] == '6.1.7600'
    end

    def windows2008r2sp1?
      windows? && self['platform_version'] == '6.1.7601'
    end

    def windows2012?
      windows? && self['platform_version'].start_with?('6.2')
    end

    def windows2012r2?
      windows? && self['platform_version'].start_with?('6.3')
    end

    def windows2016?
      windows? && self['platform_version'] == '10.0.14393'
    end

    def windows2019?
      windows? && self['platform_version'] == '10.0.17763'
    end

    def windows2022?
      windows? && self['platform_version'] == '10.0.20348'
    end

    def aristaeos?
      self['platform'] == 'arista_eos'
    end

    def embedded?
      self.aristaeos?
    end

    def systemd?
      ::File.directory?('/run/systemd/system')
    end

    def freebsd?
      self['platform_family'] == 'freebsd'
    end

    def virtual?
      vm_systems = %w{
        bhyve
        hyperv
        kvm
        parallels
        vbox
        vmware
        xen
      }
      self['virtualization'] &&
        self['virtualization']['role'] == 'guest' &&
        vm_systems.include?(self['virtualization']['system'])
    end

    def virtual_macos_type
      unless macos?
        Chef::Log.warn(
          'fb_helpers: node.virtual_macos_type called on non-macOS!',
        )
        return
      end
      return self['virtual_macos'] if self['virtual_macos']

      if self['hardware']['boot_rom_version'].include? 'VMW'
        virtual_type = 'vmware'
      elsif self['hardware']['boot_rom_version'].include? 'VirtualBox'
        virtual_type = 'virtualbox'
      else
        virtual_type = shell_out(
          '/usr/sbin/system_profiler SPEthernetDataType',
        ).run_command.stdout.to_s[/Vendor ID: (.*)/, 1]
        if virtual_type&.include?('0x1ab8')
          virtual_type = 'parallels'
        else
          virtual_type = 'physical'
        end
      end
      virtual_type
    end

    def parallels?
      virtual_macos_type == 'parallels'
    end

    def vmware?
      virtual_macos_type == 'vmware'
    end

    def virtualbox?
      virtual_macos_type == 'virtualbox'
    end

    def container?
      container_systems = %w{
        docker
        linux-vserver
        lxc
        openvz
        nspawn
      }
      result = (self['virtualization'] &&
        self['virtualization']['role'] == 'guest' &&
        container_systems.include?(self['virtualization']['system']))
      result.nil? ? false : result
    end

    def vagrant?
      File.directory?('/vagrant')
    end

    def cloud?
      self['cloud'] && !self['cloud']['provider'].nil?
    end

    def aws?
      self.cloud? && self['cloud']['provider'] == 'ec2'
    end

    # Takes one or more AWS account IDs as strings and return true if this node
    # is in any of those accounts.
    def in_aws_account?(*accts)
      return false if self.quiescent?
      return false unless self['ec2']
      accts.flatten!
      accts.include?(self['ec2']['account_id'])
    end

    def ohai_fs_ver
      @ohai_fs_ver ||=
        node['filesystem2'] ? 'filesystem2' : 'filesystem'
    end

    # Take a string representing a mount point, and return the
    # device it resides on.
    def device_of_mount(m)
      fs = self.filesystem_data
      unless Pathname.new(m).mountpoint?
        Chef::Log.warn(
          "fb_helpers: #{m} is not a mount point - I can't determine its " +
          'device.',
        )
        return nil
      end
      unless fs && fs['by_pair']
        Chef::Log.warn(
          'fb_helpers: no filesystem data so no node.device_of_mount',
        )
        return nil
      end
      fs['by_pair'].to_hash.each do |pair, info|
        # we skip fake filesystems 'rootfs', etc.
        next unless pair.start_with?('/')
        # is this our FS?
        next unless pair.end_with?(",#{m}")
        # make sure this isn't some fake entry
        next unless info['kb_size']

        return info['device']
      end
      Chef::Log.warn(
        "fb_helpers: #{m} shows as valid mountpoint, but Ohai can't find it.",
      )
      nil
    end

    def device_formatted_as?(device, fstype)
      fs = self.filesystem_data
      if fs && fs['by_device'] && fs['by_device'][device] &&
          fs['by_device'][device]['fs_type']
        return fs['by_device'][device]['fs_type'] == fstype
      end

      false
    end

    def resolve_dns_name(hostname, brackets = false, force_v4 = false)
      ip_addrs = Addrinfo.getaddrinfo(hostname, nil)
      ip_addrs_v4 = ip_addrs.select(&:ipv4?)
      ip_addrs_v6 = ip_addrs.select(&:ipv6?)
      if !ip_addrs_v6.empty? && !force_v4
        # Host supports IPv6, the answer has AAAA, let's go:
        v6_addr = ip_addrs_v6.map(&:ip_address).uniq[0]
        if brackets
          return "[#{v6_addr}]"
        else
          return v6_addr
        end
      elsif !ip_addrs_v4.empty?
        return ip_addrs_v4.map(&:ip_address).uniq[0]
      else
        fail SocketError, 'fb_helpers: No ipv4 addrs found for a non-v6 host'
      end
    end

    # Takes a string corresponding to a filesystem. Returns the size
    # in GB of that filesystem.
    def fs_value(p, val)
      key = case val
            when 'size'
              'kb_size'
            when 'used'
              'kb_used'
            when 'available'
              'kb_available'
            when 'percent'
              'percent_used'
            else
              fail "fb_helpers: Unknown FS val #{val} for node.fs_value"
            end
      fs = self.filesystem_data
      # Some things like /dev/root and rootfs have same mount point...
      if fs && fs['by_mountpoint'] && fs['by_mountpoint'][p] &&
          fs['by_mountpoint'][p][key]
        return fs['by_mountpoint'][p][key].to_f
      end

      Chef::Log.warn(
        "fb_helpers: Tried to get filesystem information for '#{p}', but it " +
        'is not a recognized filesystem, or does not have the requested info.',
      )
      nil
    end

    def fs_available_kb(p)
      self.fs_value(p, 'available')
    end

    def fs_available_gb(p)
      k = self.fs_value(p, 'available')
      if k
        return k / (1024 * 1024)
      end

      nil
    end

    def fs_size_kb(p)
      self.fs_value(p, 'size')
    end

    def fs_size_gb(p)
      k = self.fs_size_kb(p)
      if k
        return k / (1024 * 1024)
      end

      nil
    end

    def efi?
      File.directory?('/sys/firmware/efi')
    end

    def coreboot?
      File.directory?('/sys/firmware/vpd') ||
        node['dmi']['bios']['vendor'] == 'coreboot'
    end

    def aarch64?
      node['kernel']['machine'] == 'aarch64'
    end

    def x64?
      node['kernel']['machine'] == 'x86_64'
    end

    def cgroup_mounted?
      fs = self.filesystem_data
      fs && fs['by_mountpoint'] &&
        fs['by_mountpoint'].include?('/sys/fs/cgroup')
    end

    def cgroup1?
      cgroup_mounted? && self.filesystem_data['by_mountpoint'][
        '/sys/fs/cgroup']['fs_type'] != 'cgroup2'
    end

    def cgroup2?
      cgroup_mounted? && self.filesystem_data['by_mountpoint'][
        '/sys/fs/cgroup']['fs_type'] == 'cgroup2'
    end

    def get_flexible_shard(shard_size)
      if node['shard_seed']
        node['shard_seed'] % shard_size
      else
        # backwards compat for Facebook until
        # https://github.com/chef/ohai/pull/877 is out
        node['fb']['shard_seed'] % shard_size
      end
    end

    def get_seeded_flexible_shard(shard_size, string_seed = '')
      Digest::MD5.hexdigest(self['fqdn'] + string_seed)[0...7].to_i(16) %
        shard_size
    end

    def get_shard
      self.get_flexible_shard(100)
    end

    def in_flexible_shard?(shard_threshold, shard_size)
      self.get_flexible_shard(shard_size) <= shard_threshold
    end

    def in_shard?(shard_threshold)
      self.in_flexible_shard?(shard_threshold, 100)
    end

    def _timeshard_value(duration)
      # The timeshard will be the number of seconds into the duration.
      duration == 0 ? duration : self.get_flexible_shard(duration)
    end

    def timeshard_parsed_values(start_time, duration)
      # Validate the start_time string matches our prescribed format.
      st = FB::Helpers.parse_timeshard_start(start_time)

      # Coerce duration into acceptable format
      duration = FB::Helpers.parse_timeshard_duration(duration)

      # The timeshard will be the number of seconds into the duration.
      time_shard = self._timeshard_value(duration)

      # The time threshold is the sum of the start time and time shard.
      time_threshold = st + time_shard
      Chef::Log.debug(
        "fb_helpers: timeshard start time: #{start_time}, " +
        "time threshold: #{Time.at(time_threshold)}",
      )

      {
        'start_time' => st,
        'duration' => duration,
        'time_threshold' => time_threshold,
      }
    end

    def in_timeshard?(start_time, duration, stack_depth = 1)
      # Parse all of our values and
      vals = self.timeshard_parsed_values(start_time, duration)
      st = vals['start_time']
      duration = vals['duration']
      time_threshold = vals['time_threshold']

      # If the current time is greater than the threshold then the node will be
      # within the threshold of time as defined by the start time and duration,
      # and will return true.
      curtime = Time.now.tv_sec

      if curtime > st + duration
        FB::Helpers.warn_to_remove(stack_depth + 1)
      end
      curtime >= time_threshold
    end

    # This method allows you to conditionally shard chef resources
    # @param threshold [Fixnum] An integer value that you are sharding up to.
    # @yields The contents of the ruby block if the node is in the shard.
    # @example
    #  This will log 'hello' during the chef run for all nodes <= shard 5
    #   node.shard_block(5) do
    #     log 'hello' do
    #       level :info
    #     end
    #   end
    def shard_block(threshold, &block)
      yield block if block_given? && in_shard?(threshold)
    end

    def shard_over_a_week_starting(start_date)
      in_shard?(rollout_shard(start_date))
    end

    def shard_over_a_week_ending(end_date)
      start_date = Date.parse(end_date) - 7
      in_shard?(rollout_shard(start_date.to_s))
    end

    # Shard range is 0-99
    def rollout_shard(start_date)
      rollout_map = [
        1,
        10,
        25,
        50,
        99,
      ]
      rd = Date.parse(start_date)

      # Now we use today as an index into the rollout map, except we have to
      # discount weekends
      today = Date.today
      numdays = (today - rd).to_i
      num_weekend_days = 0
      (0..numdays).each do |i|
        t = rd + i
        if t.saturday? || t.sunday?
          num_weekend_days += 1
        end
      end

      # Subtract that from how far into the index we go
      numdays -= num_weekend_days

      # Return -1 because in_shard?() does a >= comparison to shard number
      if numdays < 0
        return -1
      end

      Chef::Log.debug(
        "fb_helpers: rollout_shard: days into rollout: #{numdays}",
      )

      if numdays >= rollout_map.size
        FB::Helpers.warn_to_remove(3)
        shard = 99
      else
        shard = rollout_map[numdays]
      end
      Chef::Log.debug(
        "fb_helpers: rollout_shard: rollout_shard: #{shard}",
      )
      return shard
    end

    def firstboot_os?
      # this has to work even when we fail early on so we can call this from
      # broken runs in handlers
      node['fb_init']['firstboot_os']
    rescue StandardError
      prefix = macos? ? '/var/root' : '/root'
      File.exist?(File.join(prefix, 'firstboot_os'))
    end

    def firstboot_tier?
      # this has to work even when we fail early on so we can call this from
      # broken runs in handlers
      node['fb_init']['firstboot_tier']
    rescue StandardError
      prefix = macos? ? '/var/root' : '/root'
      File.exist?(File.join(prefix, 'firstboot_tier'))
    end

    def firstboot_any_phase?
      self.firstboot_os? || self.firstboot_tier?
    end

    # is this device a SSD?  If it's not rotational, then it's SSD
    # expects a short device name, e.g. 'sda', not '/dev/sda', not '/dev/sda3'
    def device_ssd?(device)
      unless node['block_device'][device]
        fail "fb_helpers: Device '#{device}' passed to node.device_ssd? " +
             "doesn't appear to be a block device!"
      end
      node['block_device'][device]['rotational'] == '0'
    end

    def root_compressed?
      fs = self.filesystem_data
      fs && fs['by_mountpoint'] && fs['by_mountpoint']['/'] &&
        !fs['by_mountpoint']['/']['mount_options'].
          grep(/compress(-force)?=zstd/).empty?
    end

    def root_btrfs?
      fs = self.filesystem_data
      fs && fs['by_mountpoint'] && fs['by_mountpoint']['/'] &&
        fs['by_mountpoint']['/']['fs_type'] == 'btrfs'
    end

    def solo?
      Chef::Config[:solo] || Chef::Config[:local_mode]
    end

    def root_user
      value_for_platform(
        'windows' => { 'default' => 'Administrator' },
        'default' => 'root',
      )
    end

    def root_group
      # Chef moved from `macos` to `mac_os_x` between 14 and 15, so we need
      # both, but Cookstyle will tell us `macos` isn't valid.
      # rubocop:disable ChefCorrectness/InvalidPlatformValueForPlatformHelper
      value_for_platform(
        %w{openbsd freebsd mac_os_x macos} => { 'default' => 'wheel' },
        'windows' => { 'default' => 'Administrators' },
        'default' => 'root',
      )
      # rubocop:enable ChefCorrectness/InvalidPlatformValueForPlatformHelper
    end

    def quiescent?
      # if this is set, we're trying to be small and anonymous
      File.exist?('/root/quiesce')
    end

    # On Linux and Mac, as of Chef 13, FS and FS2 were identical
    # and in Chef 14, FS2 is dropped.
    #
    # For FreeBSD and other platforms, they become identical in late 15
    # and FS2 is dropped in late 16
    #
    # So we always try 2 and fail back to 1 (if 2 isn't around, then 1
    # is the new format)
    #
    # This will return modern filesystem data, where it exists *if* it exists.
    # Otherwise it will fail
    def filesystem_data
      self['filesystem2'] || self['filesystem']
    end

    # returns the version-release of an rpm installed, or nil if not present
    def rpm_version(name)
      if (self.centos? && !self.centos7?) || self.fedora?
        # returns epoch.version
        v = Chef::Provider::Package::Dnf::PythonHelper.instance.
            package_query(:whatinstalled, name).version
        unless v.nil?
          v.split(':')[1]
        end
      elsif self.centos7? &&
        (FB::Version.new(Chef::VERSION) > FB::Version.new('14'))
        # returns epoch.version.arch
        v = Chef::Provider::Package::Yum::PythonHelper.instance.
            package_query(:whatinstalled, name).version
        unless v.nil?
          v.split(':')[1]
        end
      else
        # return version
        Chef::Provider::Package::Yum::YumCache.instance.
          installed_version(name)
      end
    end

    def selinux_mode
      node['selinux']['status']['current_mode'] || 'unknown'
    end

    def selinux_policy
      node['selinux']['status']['loaded_policy_name']
    end

    def selinux_enabled?
      node['selinux']['status']['selinux_status'] == 'enabled'
    end

    def host_chef_base_path
      if node.windows?
        File.join('C:', 'chef')
      else
        File.join('/var', 'chef')
      end
    end

    def solo_chef_base_path
      if node.windows?
        File.join('C:', 'chef', 'solo')
      else
        File.join('/opt', 'chef-solo')
      end
    end

    def chef_base_path
      if node.solo?
        self.solo_chef_base_path
      else
        self.host_chef_base_path
      end
    end

    def taste_tester_mode?
      Chef::Config[:mode] == 'taste-tester'
    end

    # Safely dig through the node's attributes based on the specified `path`,
    # with the option to provide a default value
    # in the event the key does not exist.
    #
    # @param path [required] [String] A string representing the path to search
    # for the key.
    # @param delim [opt] [String] A character that you will split the path on.
    # @param default [opt] [Object] An object to return if the key is not found.
    # @return [Object] Returns an arbitrary object in the event the key isn't
    # there.
    # @note Returns nil by default
    # @note Returns the default value in the event of an exception
    # @example
    #  irb> node.default.awesome = 'yup'
    #  => "yup"
    #  irb> node.attr_lookup('awesome/not_there')
    #  => nil
    #  irb> node.attr_lookup('awesome')
    #  => "yup"
    #  irb> node.override.not_cool = 'but still functional'
    #  => "but still functional"
    #  irb> node.attr_lookup('not_cool')
    #  => "but still functional"
    #  irb> node.attr_lookup('default_val', default: 'I get this back anyway')
    #  => "I get this back anyway"
    #  irb> node.automatic.a.very.deeply.nested.value = ':)'
    #  => ":)"
    #  irb> node.attr_lookup('a/very/deeply/nested/value')
    #  => ":)"
    def attr_lookup(path, delim: '/', default: nil)
      return default if path.nil?

      node_path = path.split(delim)
      # implicit-begin is a function of ruby2.5 and later, but we still
      # support 2.4, so.... until then
      # rubocop:disable Style/RedundantBegin
      node_path.inject(self) do |location, key|
        begin
          location.attribute?(key.to_s) ? location[key] : default
        rescue NoMethodError
          default
        end
      end
      # rubocop:enable Style/RedundantBegin
    end

    def default_package_manager
      cls = Chef::ResourceResolver.resolve(:package, :node => node)
      if cls
        m = cls.to_s.match(/Chef::Resource::(\w+)Package/)
        if m[1]
          m[1].downcase
        else
          fail "fb_helpers: unknown package manager resource class: #{cls}"
        end
      else
        fail 'fb_helpers: undefined package manager resource class!'
      end
    end

    def nw_changes_allowed?
      method = node['fb_helpers']['network_changes_allowed_method']
      if method
        return method.call(node)
      else
        return @nw_changes_allowed unless @nw_changes_allowed.nil?
        @nw_changes_allowed = node.firstboot_any_phase? ||
        ::File.exist?(::FB::Helpers::NW_CHANGES_ALLOWED)
      end
    end

    # We can change interface configs if nw_changes_allowed? or we are operating
    # on a DSR VIP
    def interface_change_allowed?(interface)
      method = node['fb_helpers']['interface_change_allowed_method']
      if method
        return method.call(node, interface)
      else
        return self.nw_changes_allowed? ||
          ['ip6tnl0', 'tunlany0', 'tunl0'].include?(interface) ||
          interface.match(Regexp.new('^tunlany\d+:\d+'))
      end
    end

    def interface_start_allowed?(interface)
      method = node['fb_helpers']['interface_start_allowed_method']
      if method
        return method.call(node, interface)
      else
        return self.interface_change_allowed?(interface)
      end
    end
  end
end
