# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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
#

module FB
  module FbSwap
    def self._validate(node)
      device = self._device(node)
      file = self._file(node)
      # Let's look at /proc/swaps for actual size. We can't examine swap
      # partitions formatted size unless they're "mounted" here. This also
      # produces a list of swap files mounted.
      swaps_enabled = self._get_swaps_enabled

      if device
        max_device_size_bytes = self._get_max_device_size_bytes(device)
        # there is a swap device, we'll default it to not mounted. A negative
        # size will ensure we format it (again) before mounting it due to
        # inequality
        device_current_size_bytes = -1
      else
        max_device_size_bytes = 0
        # no swap device, so it has no concept of size.
        device_current_size_bytes = nil
      end

      # If there is an umounted swap file, we don't know the 'formatted' size
      file_current_size_bytes = -1

      # ensure we only have things enabled that we understand
      swaps_enabled.each do |swap|
        if device && swap['file'] == device && swap['mode'] == 'partition'
          # found swap partition
          device_current_size_bytes = swap['size_bytes']
        elsif swap['file'] == file && swap['mode'] == 'file'
          # found the swap file
          file_current_size_bytes = swap['size_bytes']
        else
          fail "fb_swap: Found an unmanaged swap: #{swap}"
        end
      end

      if node['fb_swap']['enabled']
        size = node['fb_swap']['size']
      else
        size = 0
      end

      if size.nil?
        # size nil means use full, existing swap device
        if max_device_size_bytes.zero?
          msg = 'fb_swap: default swap is requested, but there\'s no swap ' +
            'partition so no implicit size. Set node.default[\'fb_swap\']' +
            '[\'size\'] to something specific if you want to use a swap file'
          if node['fb_swap']['strict']
            fail msg
          else
            Chef::Log.warn(msg)
            device_size_bytes = 0
            file_size_bytes = 0
          end
        else
          # default is to use all of the swap device, no swap file
          device_size_bytes = max_device_size_bytes
          file_size_bytes = 0
        end
      else
        # API is in KB, convert to bytes for lowest common denominator
        size_bytes = size * 1024
        if size_bytes % 4096 != 0
          fail "fb_swap::default: #{size_bytes} bytes is not an even number " +
               'of 4KiB pages'
        elsif size_bytes <= 1048576 && node['fb_swap']['enabled']
          fail "fb_swap::default: #{size_bytes} is less than 1MiB. Use " +
               'enabled = false instead'
        elsif node['fb_swap']['filesystem'] != '/'
          device_size_bytes = 0
          file_size_bytes = size_bytes
        elsif size_bytes <= max_device_size_bytes
          device_size_bytes = size_bytes
          file_size_bytes = 0
        else
          device_size_bytes = max_device_size_bytes
          file_size_bytes = size_bytes - max_device_size_bytes
        end
      end

      if file_size_bytes.positive? && !self.swap_file_possible?(node)
        fail "fb_swap: swap file of #{file_size_bytes} requested, but " +
             'system does not support it. See previous log lines for ' +
             'warnings that explain why'
      end

      if device
        swapoff_needed, device_size_bytes = self._validate_resize(
          node, 'device', device_size_bytes, device_current_size_bytes
        )
      else
        swapoff_needed = false
      end
      file_swapoff_needed, file_size_bytes = self._validate_resize(
        node, 'file', file_size_bytes, file_current_size_bytes
      )
      swapoff_needed ||= file_swapoff_needed

      node.default['fb_swap']['_calculated'] = {
        'device_size_bytes' => device_size_bytes,
        'device_current_size_bytes' => device_current_size_bytes,
        'file_size_bytes' => file_size_bytes,
        'file_current_size_bytes' => file_current_size_bytes,
        'swapoff_needed' => swapoff_needed,
      }
    end

    def self._validate_resize(node, type, size_bytes, current_size_bytes)
      # returns a pair:
      # swapoff needed: boolean
      # size_bytes: size to use
      if current_size_bytes == -1
        # current size is not-enabled. We might be leaving disabled or enabling
        # both of which are safe and involve no swapoff.
        return false, size_bytes
      elsif size_bytes != current_size_bytes
        Chef::Log.debug(
          "fb_swap: #{type} size changed from #{current_size_bytes} to " +
          "#{size_bytes} delta = #{size_bytes - current_size_bytes} bytes",
        )
        reason = node['fb_swap']['swapoff_allowed_because']
        if reason
          Chef::Log.debug("fb_swap: resizing #{type} allowed because #{reason}")
          return true, size_bytes
        else
          # Failing a chef run for the inability to resize swap is
          # overzealous. We chose not to, to allow the recipe to define
          # a second way to set swapoff_allowed_because via a flag file.
          Chef::Log.error(
            "fb_swap: swap #{type} size change requested requires a " +
            '\'swapoff\'. This is not safe. You can whitelisted with ' +
            '\'swapoff_allowed_because\' API. Size change reverted.',
          )
          # a number of resources look at whether swap is enabled or not. If
          # we get here, then swap must stay enabled, so change it back.
          node.default['fb_swap']['enabled'] = true
          # we are not doing a swapoff, and we are going to reset the
          # size calculated to the current size instead of what was
          # requested.
          return false, current_size_bytes
        end
      end
      # default case is we are not using swapoff
      [false, size_bytes]
    end

    def self._device(node)
      swap_mounts = node.filesystem_data['by_device'].to_hash.select do |_k, v|
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

    def self._file(node)
      filesystem = node['fb_swap']['filesystem']
      filesystem += '/' unless filesystem.end_with?('/')
      "#{filesystem}swapvol/swapfile"
    end

    def self._path(node, type)
      case type
      when 'device'
        self._device(node)
      when 'file'
        self._file(node)
      end
    end

    def self._swap_unit(node, type)
      FB::Systemd.path_to_unit(self._path(node, type), 'swap')
    end

    def self._get_max_device_size_bytes(device)
      cmd = Mixlib::ShellOut.new([
        '/usr/sbin/blockdev',
        '--getsize64',
        device,
      ]).run_command
      cmd.error!
      size = cmd.stdout.to_i
      if size < 4096
        fail 'fb_swap: swap device is too small to contain swap header'
      end
      size
    end

    def self._get_swaps_enabled
      cmd = Mixlib::ShellOut.new([
        '/usr/sbin/swapon',
        '--show=NAME,TYPE,SIZE,USED',
        '--raw',
        '--bytes',
        '--noheadings',
      ]).run_command
      cmd.error!

      cmd.stdout.each_line.collect do |line|
        file, mode, size_bytes, used_bytes = line.chomp.split
        {
          'file' => file,
          'mode' => mode,
          # add 4k to the size to add the header back in
          'size_bytes' => size_bytes.to_i + 4096,
          'used_bytes' => used_bytes.to_i,
        }
      end
    end

    def self._filesystem_map_for_fs(node)
      node.filesystem_data['by_mountpoint'][node['fb_swap']['filesystem']]
    end

    def self.swap_file_possible?(node)
      if _filesystem_map_for_fs(node)['fs_type'] == 'btrfs'
        # The historical take on btrfs is that swap files are not supported.
        # This is changing soon (4.16+?). There's no feature test for this
        # (yet?) so we'll be pessimistic and say no.
        Chef::Log.warn('fb_swap: Swap file not generally possible on btrfs')
        return false
      end
      return !self._on_rotational?(node)
    end

    def self._on_rotational?(node)
      _filesystem_map_for_fs(node)['devices'].each do |dev|
        lsblk = Mixlib::ShellOut.new("lsblk --json --output ROTA #{dev}")
        lsblk.run_command.error!
        block_device = JSON.parse(lsblk.stdout)['blockdevices'][0]
        if block_device['rota'] == '1'
          Chef::Log.debug(
            "fb_swap: Swap file not possible due to rotational device #{dev}",
          )
          return true
        end
      end
      Chef::Log.debug(
        'fb_swap: Swap file possible (no rotational device members on ' +
        'filesytem)',
      )
      return false
    end
  end
end
