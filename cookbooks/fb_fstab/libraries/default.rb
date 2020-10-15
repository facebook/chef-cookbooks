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

module FB
  # Fstab utility functions
  unless defined?(FB::Fstab)
    class Fstab
      BASE_FILENAME = '/etc/.fstab.chef'.freeze
      IN_MAINT_DISKS_FILENAME = '/var/chef/in_maintenance_disks'.freeze
      IN_MAINT_MOUNTS_FILENAME = '/var/chef/in_maintenance_mounts'.freeze
      BTRFS_ROOTPARENT = '5'.freeze

      def self.determine_base_fstab_entries(full_fstab)
        core_fs_line_matching = [
          '^LABEL=(\/|\/boot|SWAP.*|\/mnt\/d\d+)\s',
          '^\S+\s/\s',
          '^UUID=',
          '^devpts',
          '^sysfs',
          '^proc',
          '^tmpfs\s+\/dev\/shm.*',
          '^/dev/sda',
          '^/dev/fioa',
          '^/dev/mapper',
        ]

        base = ''

        full_fstab.split("\n").each do |line|
          iscore = core_fs_line_matching.any? do |thing|
            line =~ /#{thing}/
          end
          # These messages are technically debug lines, but since it only
          # happens once and we'll want to know this for debugging, it's going
          # in as info.
          unless iscore
            Chef::Log.info("FB::Fstab.generate_base_fstab: Skipping #{line}")
            next
          end
          Chef::Log.info("FB::Fstab.generate_base_fstab: Keeping #{line}")
          base << "#{line}\n"
        end
        base
      end

      def self.generate_base_fstab
        unless File.exist?(BASE_FILENAME) && File.size?(BASE_FILENAME)
          FileUtils.cp('/etc/fstab', '/root/fstab.before_fb_fstab')
          FileUtils.chmod(0400, '/root/fstab.before_fb_fstab')
          full_fstab = File.read('/etc/fstab')
          base_fstab = determine_base_fstab_entries(full_fstab)
          File.write(BASE_FILENAME, base_fstab)
        end
      end

      # Returns the content of the file
      def self.base_fstab_contents(node)
        unless node['fb_fstab']['_basefilecontents']
          node.default['fb_fstab']['_basefilecontents'] =
            File.read(BASE_FILENAME)
        end
        node['fb_fstab']['_basefilecontents']
      end

      # Returns an array of strings
      def self.parse_in_maint_file(path)
        return [] unless File.exist?(path)

        age = (
          Time.now - File.stat(path).mtime
        ).to_i
        if age > 60 * 60 * 24 * 7
          Chef::Log.warn(
            "fb_fstab: Removing stale #{path} - it is more than 1 week old.",
          )
          File.unlink(path)
          return []
        end
        entries = []
        File.read(path).each_line do |line|
          next if line.start_with?('#')
          next if line.strip.empty?

          entries << line.strip
        end
        entries
      end

      # Returns an array of disks
      def self.get_in_maint_disks
        disks = self.parse_in_maint_file(IN_MAINT_DISKS_FILENAME)
        unless disks.empty?
          Chef::Log.warn(
            "fb_fstab: Will skip in-maintenance disks: #{disks.join(' ')}",
          )
        end
        disks
      end

      # Returns an array of mounts
      def self.get_in_maint_mounts
        mounts = self.parse_in_maint_file(IN_MAINT_MOUNTS_FILENAME)
        # Canonicalize mount paths (e.g. removing trailing slashes)
        mounts.map! { |m| Pathname.new(m).cleanpath.to_s }
        unless mounts.empty?
          Chef::Log.warn(
            "fb_fstab: Will skip in-maintenance mounts: #{mounts.join(' ')}",
          )
        end
        mounts
      end

      def self.get_autofs_points(node)
        autofs_points = []
        node.filesystem_data['by_pair'].to_hash.each_value do |data|
          autofs_points << data['mount'] if data['fs_type'] == 'autofs'
        end
        autofs_points
      end

      def self.autofs_parent(dir, node)
        get_autofs_points(node).each do |pt|
          Chef::Log.debug(
            "fb_fstab: Checking if #{dir} is within autofs tree at #{pt}",
          )
          if dir.start_with?(pt)
            Chef::Log.debug('fb_fstab: it is!')
            return pt
          end
        end
        false
      end

      def self.label_to_device(label, node)
        d = node.filesystem_data['by_device'].select do |x, y|
          y['label'] && y['label'] == label && !x.start_with?('/dev/block')
        end
        fail "Requested disk label #{label} doesn't exist" if d.empty?

        Chef::Log.debug("fb_fstab: label #{label} is device #{d.keys[0]}")
        d.keys[0]
      end

      def self.uuid_to_device(uuid, node)
        d = node.filesystem_data['by_device'].to_hash.select do |x, y|
          y['uuid'] && y['uuid'] == uuid && !x.start_with?('/dev/block')
        end
        fail "Requested disk UUID #{uuid} doesn't exist" if d.empty?

        Chef::Log.debug("fb_fstab: uuid #{uuid} is device #{d.keys[0]}")
        d.keys[0]
      end

      def self.canonicalize_device(device, node)
        Chef::Log.debug("fb_fstab: Canonicalizing #{device}")
        if device.start_with?('LABEL=')
          label = device.sub('LABEL=', '')
          device = label_to_device(label, node)
        elsif device.start_with?('UUID=')
          uuid = device.sub('UUID=', '')
          device = uuid_to_device(uuid, node)
        end
        device
      end

      # This will always return the id of the subvolume specified in the option
      def self._canonicalize_subvol_opt(mount, opts)
        type = ''
        value = ''

        opts.split(',').each do |option|
          if option.include?('subvol=') || option.include?('subvolid=')
            data = option.split('=')
            type = data[0]
            value = data[1]
            break
          end
        end

        if type == 'subvolid' && !value.empty?
          return value
        elsif type != 'subvol'
          fail "fb_fstab: Cannot canonicalize subvolume from options: #{opts}"
        end

        cmd = "/usr/sbin/btrfs subvol list #{mount}"
        subvolume_data = Mixlib::ShellOut.new(cmd).run_command
        subvolume_data.error!

        subvolume_data.stdout.each_line do |line|
          # eg. ID 260 gen 49 top level 5 path cache
          fields = line.split(' ')

          if fields[8] == value
            return fields[1]
          end
        end
        fail "fb_fstab: Cannot canonicalize subvolume: #{opts}"
      end

      def self.same_subvol?(mount, opts1, opts2)
        a = self._canonicalize_subvol_opt(mount, opts1)
        b = self._canonicalize_subvol_opt(mount, opts2)
        a == b
      end

      def self.btrfs_subvol?(fs_type, mount_options)
        fs_type == 'btrfs' &&
          (
            mount_options.include?('subvol=') ||
            mount_options.include?('subvolid=')
          )
      end

      def self.get_unmasked_base_mounts(format, node, hash_by = 'device')
        res = case format
              when :hash
                {}
              when :lines
                []
              end
        hash_by_values = Set['device', 'mount_point']
        unless hash_by_values.include?(hash_by)
          fail "fb_fstab: Invalid hash_by value, allowed are: #{hash_by_values}"
        end
        desired_mounts = node['fb_fstab']['mounts'].to_hash
        FB::Fstab.base_fstab_contents(node).each_line do |line|
          next if line.strip.empty?
          # do not add swap if swap is managed elsewhere, e.g. fb_swap
          next if line.include?('swap') && node['fb_fstab']['exclude_base_swap']

          line_parts = line.strip.split
          line_dev_spec = line_parts[0]

          # if someone specifies the same device in a mount that is in the
          # mounts we got from provisioning, then they are trying to override
          # that. We only look at the `device` part here because we shouldn't
          # have things like NFS or other such things specified in provisioning
          # anyway.
          next if desired_mounts.any? do |_name, data|
            line_dev_spec == data['device']
          end

          # If that failed, we canonicalize (if possible) and try again against
          # canonicalized versions of what's in the user's config
          begin
            fs_spec = canonicalize_device(line_dev_spec, node)
          rescue StandardError => e
            # Special handing for UUIDs. I hate UUIDs. Really, did I mention I
            # hate UUIDs? Who thought those were a good idea. Anyway in the
            # event we got UUIDs from provisioning and the user wants to use
            # labels, let that happen.
            raise e unless line_dev_spec.start_with?('UUID=')
            next if desired_mounts.any? do |_name, data|
              data['mount_point'] == line_parts[1] &&
                data['device'].start_with?('LABEL=')
            end

            raise e
          end
          # If someone has a more specific mount, don't use the original
          next if desired_mounts.any? do |_name, data|
            begin
              cdev = canonicalize_device(data['device'], node)
            rescue RuntimeError => e
              # If the entry in node['fstab']['mounts] failed to resolve,
              # that's an error, orthogonal to what we're doing here,
              # unless they set `allow_mount_failure`. So if it failed,
              # raise an error, otherwise don't.
              #
              # HOWEVER, this `next` is not `next true`, because we're
              # not skipping the mount - there was no valid comparison
              # done. We're just moving to the next iteration of any?`
              next if data['allow_mount_failure']

              raise e
            end
            # We want to skip btrfs subvolumes as
            # it's valid to specifiy the same device multiple times
            [data['device'], cdev].include?(fs_spec) &&
              !self.btrfs_subvol?(data['type'], data['opts'])
          end

          case format
          when :hash
            mount_point = line_parts[1]
            case hash_by
            when 'device'
              res[fs_spec] = {
                'mount_point' => mount_point,
                'type' => line_parts[2],
                'opts' => line_parts[3],
                'dump' => line_parts[4],
                'pass' => line_parts[5],
              }
            when 'mount_point'
              res[mount_point] = {
                'device' => fs_spec,
                'type' => line_parts[2],
                'opts' => line_parts[3],
                'dump' => line_parts[4],
                'pass' => line_parts[5],
              }
            end
          when :lines
            res << line.strip
          end
        end
        Chef::Log.debug("fb_fstab: base mounts: #{res}")
        res
      end
    end
  end
  # https://github.com/jamesmartin/chefspec/pull/1/files
  # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
  # http://jtimberman.housepub.org/blog/2015/05/30/quick-tip-stubbing-library-helpers-in-chefspec/
end
