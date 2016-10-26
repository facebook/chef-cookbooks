# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

class Chef
  # Our extensions of the node object
  class Node
    def centos?
      return self['platform'] == 'centos'
    end

    def centos7?
      return self.centos? && self['platform_version'].start_with?('7')
    end

    def centos6?
      return self.centos? && self['platform_version'].start_with?('6')
    end

    def centos5?
      return self.centos? && self['platform_version'].start_with?('5')
    end

    def debian?
      return self['platform'] == 'debian'
    end

    def ubuntu?
      return self['platform'] == 'ubuntu'
    end

    def ubuntu12?
      return self.ubuntu? && self['platform_version'].start_with?('12')
    end

    def ubuntu14?
      return self.ubuntu? && self['platform_version'].start_with?('14')
    end

    def ubuntu16?
      return self.ubuntu? && self['platform_version'].start_with?('16')
    end

    def linux?
      return self['os'] == 'linux'
    end

    def redhat?
      return self['platform'] == 'redhat'
    end

    def redhat6?
      return self.redhat? && self['platform_version'].start_with?('6')
    end

    def redhat7?
      return self.redhat? && self['platform_version'].start_with?('7')
    end

    def oracle?
      return self['platform'] == 'oracle'
    end

    def oracle7?
      return self.oracle? && self['platform_version'].start_with?('7')
    end

    def oracle6?
      return self.oracle? && self['platform_version'].start_with?('6')
    end

    def oracle5?
      return self.oracle? && self['platform_version'].start_with?('5')
    end

    def macosx?
      return self['platform'] == 'mac_os_x'
    end

    def windows?
      return self['os'] == 'windows'
    end

    def yocto?
      return self['platform_family'] == 'yocto'
    end

    def systemd?
      return ::File.directory?('/run/systemd/system')
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
      return self['virtualization'] &&
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
      return self['virtualization'] &&
        self['virtualization']['role'] == 'guest' &&
        container_systems.include?(self['virtualization']['system'])
    end

    def vagrant?
      return File.directory?('/vagrant')
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
      return nil
    end

    def device_formatted_as?(device, fstype)
      if node['filesystem2']['by_device'][device] &&
         node['filesystem2']['by_device'][device]['fs_type']
        return node['filesystem2']['by_device'][device]['fs_type'] == fstype
      end
      return false
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
      if self['filesystem2']
        fs = self['filesystem2']['by_mountpoint'][p]
        # Some things like /dev/root and rootfs have same mount point...
        if fs && fs[key]
          return fs[key].to_f
        end
      else
        self['filesystem'].to_hash.values.each do |fsm|
          # Some things like /dev/root and rootfs have same mount point...
          # centos7 reports label instead of mount point
          if (fsm['mount'] == p || fsm['label'] == p) && fsm[key]
            return fsm[key].to_f
          end
        end
      end
      Chef::Log.warn(
        "Tried to get filesystem information for '#{p}', but it is not a " +
        'recognized filesystem, or does not have the requested info.',
      )
      return nil
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
      # We cannot rely on the existence of /sys/firmware/efi, as it only
      # appears when the kernel module efivars is inserted, and that doesn't
      # always happen. On the contrary, for booting into EFI you need /boot/efi
      # mounted as a VFAT partition, and that's what we will use.
      return File.exists?('/boot/efi') && node.device_of_mount('/boot/efi')
    end

    def aarch64?
      return node['kernel']['machine'] == 'aarch64'
    end

    def x64?
      return node['kernel']['machine'] == 'x86_64'
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

    def in_flexible_shard?(shard_threshold, shard_size)
      self.get_flexible_shard(shard_size) <= shard_threshold
    end

    def in_shard?(shard_threshold)
      self.in_flexible_shard?(shard_threshold, 100)
    end
  end
end
