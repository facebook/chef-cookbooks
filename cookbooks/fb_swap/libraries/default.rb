# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
#

module FB
  module FbSwap
    def self.get_current_swap_device(node)
      swap_mounts = node['filesystem2']['by_device'].to_hash.select do |_k, v|
        v['fs_type'] == 'swap'
      end

      case swap_mounts.count
      when 0
        return nil
      when 1
        return swap_mounts.keys[0]
      else
        fail 'More than one swap mount found, this is not right.'
      end
    end

    def self._root_filesystem(node)
      node['filesystem2']['by_mountpoint']['/']
    end

    def self.get_current_swap_unit(node)
      return FB::Systemd.path_to_unit(
        get_current_swap_device(node),
        'swap',
      )
    end

    def self.swap_file_possible?(node)
      if _root_filesystem(node)['fs_type'] == 'btrfs'
        # The historical take on btrfs is that swap files are not supported.
        # This is changing soon (4.16+?). There's no feature test for this
        # (yet?) so we'll be pessimistic and say no.
        Chef::Log.warn('fb_swap: Swap file not generally possible on btrfs')
        return false
      end
      return self._root_on_rotational?(node)
    end

    def self._root_on_rotational?(node)
      _root_filesystem(node)['devices'].each do |dev|
        match = %r/\/dev\/(?<block>[[:alpha:]]+)[[:digit:]]/.match(dev)
        # assert we can find a block device name in here
        return false unless match
        block_device = match['block']
        if node['block_device'][block_device]['rotational'] == '1'
          Chef::Log.warn(
            'fb_swap: Swap file not possible due to rotational device ' +
            block_device,
          )
          return false
        end
      end
      Chef::Log.debug(
        'fb_swap: Swap file possible (no rotational device members on root ' +
        'filesytem)',
      )
      return true
    end
  end
end
