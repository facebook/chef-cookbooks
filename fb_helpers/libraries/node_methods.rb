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

    def ubuntu?
      return self['platform'] == 'ubuntu'
    end

    def linux?
      return self['os'] == 'linux'
    end

    def macosx?
      return self['platform'] == 'mac_os_x'
    end

    def yocto?
      return self['platform_family'] == 'yocto'
    end

    def systemd?
      return ::File.directory?('/run/systemd/system')
    end

    def virtual?
      return self['virtualization'] &&
        self['virtualization']['role'] == 'guest'
    end

    def container?
      if ENV['container'] && ENV['container_uuid']
        return true
      else
        return false
      end
    end

    # Take a string representing a mount point, and return the
    # device it resides on.
    def device_of_mount(m)
      unless Pathname.new(m).mountpoint?
        Chef::Log.warn(
          "#{m} is not a mount point - I can't determine its device.")
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
        "#{m} shows as valid mountpoint, but Ohai can't find it.")
      return nil
    end

    def efi?
      # We cannot rely on the existence of /sys/firmware/efi, as it only
      # appears when the kernel module efivars is inserted, and that doesn't
      # always happen. On the contrary, for booting into EFI you need /boot/efi
      # mounted as a VFAT partition, and that's what we will use.
      return File.exists?('/boot/efi') && node.device_of_mount('/boot/efi')
    end
  end
end
