# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

module FB
  # Fstab utilitiy functions
  unless defined?(FB::Fstab)
    class Fstab
      BASE_FILENAME = '/etc/.fstab.chef'.freeze
      IN_MAINT_DISKS_FILENAME = '/var/chef/in_maintenance_disks'.freeze

      def self.determine_base_fstab_entries(full_fstab)
        core_fs_line_matching = [
          '^LABEL=(\/|\/boot|SWAP.*|\/mnt\/d\d+)\s',
          '^UUID=',
          '^devpts',
          '^sysfs',
          '^proc',
          '^tmpfs\s+\/dev\/shm.*',
          '^/dev/sda',
          '^/dev/fioa',
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
        unless File.exist?(BASE_FILENAME) && File.size(BASE_FILENAME) > 0
          FileUtils.cp('/etc/fstab', '/root/fstab.before_fb_fstab')
          FileUtils.chmod(0400, '/root/fstab.before_fb_fstab')
          full_fstab = File.read('/etc/fstab')
          base_fstab = determine_base_fstab_entries(full_fstab)
          File.write(BASE_FILENAME, base_fstab)
        end
      end

      # Returns the content of the file
      def self.load_base_fstab
        File.read(BASE_FILENAME)
      end

      # Returns an array of disks
      def self.get_in_maint_disks
        return [] unless File.exist?(IN_MAINT_DISKS_FILENAME)
        age = (
          Time.now - File.stat(IN_MAINT_DISKS_FILENAME).mtime
        ).to_i
        if age > 60 * 60 * 24 * 7
          Chef::Log.warn(
            "fb_fstab: Removing stale #{IN_MAINT_DISKS_FILENAME} " +
            '- it is more than 1 week old.',
          )
          File.unlink(IN_MAINT_DISKS_FILENAME)
          return []
        end
        disks = []
        File.read(IN_MAINT_DISKS_FILENAME).each_line do |line|
          next if line.start_with?('#')
          disks << line.strip
        end
        unless disks.empty?
          Chef::Log.warn(
            "fb_fstab: Will skip in-maintenance disks: #{disks.join(' ')}",
          )
        end
        return disks
      end

      def self.get_autofs_points(node)
        autofs_points = []
        node['filesystem2']['by_pair'].to_hash.each_value do |data|
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
        d = node['filesystem2']['by_device'].select do |x, y|
          y['label'] && y['label'] == label && !x.start_with?('/dev/block')
        end
        fail "Requested disk label #{label} doesn't exist" if d.empty?
        Chef::Log.debug("fb_fstab: label #{label} is device #{d.keys[0]}")
        d.keys[0]
      end

      def self.uuid_to_device(uuid, node)
        d = node['filesystem2']['by_device'].to_hash.select do |x, y|
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
    end
  end
  # https://github.com/jamesmartin/chefspec/pull/1/files
  # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
  # http://jtimberman.housepub.org/blog/2015/05/30/quick-tip-stubbing-library-helpers-in-chefspec/
end
