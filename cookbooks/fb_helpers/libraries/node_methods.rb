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

    def fedora28?
      self.fedora? && self['platform_version'] == '28'
    end

    def fedora29?
      self.fedora? && self['platform_version'] == '29'
    end

    def redhat?
      self['platform'] == 'redhat'
    end

    def debian?
      self['platform'] == 'debian'
    end

    def ubuntu?
      self['platform'] == 'ubuntu'
    end

    def ubuntu16?
      self.ubuntu? && self['platform_version'] == '16'
    end

    def linux?
      self['os'] == 'linux'
    end

    def macos?
      self['platform'] == 'mac_os_x'
    end

    alias macosx? macos?

    def windows?
      self['os'] == 'windows'
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

    def container?
      container_systems = %w{
        docker
        linux-vserver
        lxc
        openvz
      }
      self['virtualization'] &&
        self['virtualization']['role'] == 'guest' &&
        container_systems.include?(self['virtualization']['system'])
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

    # Take a string representing a mount point, and return the
    # device it resides on.
    def device_of_mount(m)
      unless Pathname.new(m).mountpoint?
        Chef::Log.warn(
          "#{m} is not a mount point - I can't determine its device.",
        )
        return nil
      end
      node['filesystem2']['by_pair'].to_hash.each do |pair, info|
        # we skip fake filesystems 'rootfs', etc.
        next unless pair.start_with?('/')
        # is this our FS?
        next unless pair.end_with?(",#{m}")
        # make sure this isn't some fake entry
        next unless info['kb_size']
        return info['device']
      end
      Chef::Log.warn(
        "#{m} shows as valid mountpoint, but Ohai can't find it.",
      )
      nil
    end

    def device_formatted_as?(device, fstype)
      if node['filesystem2']['by_device'][device] &&
         node['filesystem2']['by_device'][device]['fs_type']
        return node['filesystem2']['by_device'][device]['fs_type'] == fstype
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
        fail SocketError, 'No ipv4 addrs found for a non-v6 host'
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
              fail "fb_util[node.fs_val]: Unknown FS val #{val}"
            end
      fs = self['filesystem2']['by_mountpoint'][p]
      # Some things like /dev/root and rootfs have same mount point...
      if fs && fs[key]
        return fs[key].to_f
      end
      Chef::Log.warn(
        "Tried to get filesystem information for '#{p}', but it is not a " +
        'recognized filesystem, or does not have the requested info.',
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
      node['filesystem2']['by_mountpoint'].include?('/sys/fs/cgroup')
    end

    def cgroup1?
      cgroup_mounted? && node['filesystem2']['by_mountpoint'][
        '/sys/fs/cgroup']['fs_type'] != 'cgroup2'
    end

    def cgroup2?
      cgroup_mounted? && node['filesystem2']['by_mountpoint'][
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

    def firstboot_os?
      # this has to work even when we fail early on so we can call this from
      # broken runs in handlers
      node['fb_init'] && node['fb_init']['firstboot_os']
    end

    def firstboot_tier?
      # this has to work even when we fail early on so we can call this from
      # broken runs in handlers
      node['fb_init'] && node['fb_init']['firstboot_tier']
    end

    def firstboot_any_phase?
      self.firstboot_os? || self.firstboot_tier?
    end

    # is this device a SSD?  If it's not rotational, then it's SSD
    # expects a short device name, e.g. 'sda', not '/dev/sda', not '/dev/sda3'
    def device_ssd?(device)
      unless node['block_device'][device]
        fail "device_ssd?: Device '#{device}' doesn't appear to be a block " +
          'device!'
      end
      node['block_device'][device]['rotational'] == '0'
    end
  end
end
