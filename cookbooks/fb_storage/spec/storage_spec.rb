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

require './spec/spec_helper'
require_relative '../../fb_fstab/libraries/default'
require_relative '../../fb_helpers/libraries/node_methods'
require_relative '../libraries/storage'

describe FB::Storage do
  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end

  before do
    node.automatic['fb'] = {}
  end

  context '#eligble_devices' do
    it 'should not include root drives' do
      node.automatic['block_device'] = {
        'sda' => {},
        'sdb' => {},
      }
      allow(node).to receive(:device_of_mount).with('/').and_return('/dev/sda')

      expect(FB::Storage.eligible_devices(node)).to eq(['sdb'])
    end

    it 'should skip ram, loop, and md devices' do
      node.automatic['block_device'] = {
        'sda' => {},
        'fioa' => {},
        'loop0' => {},
        'ram0' => {},
        'md0' => {},
      }

      allow(node).to receive(:device_of_mount).with('/').and_return('/dev/sda')

      expect(FB::Storage.eligible_devices(node)).to eq(['fioa'])
    end
  end

  context '#root_device_name' do
    it 'should work when root is a partition' do
      {
        'sda1' => 'sda',
        'nvme0n1p1' => 'nvme0n1',
      }.each do |partition, device|
        node.automatic['block_device'][device] = {}
        allow(node).to receive(:device_of_mount).with('/').and_return(
          "/dev/#{partition}",
        )
        expect(FB::Storage.root_device_name(node)).to eq(device)
      end
    end

    it 'should work when root is a bare device' do
      %w{
        sda
        md0
      }.each do |device|
        node.automatic['block_device'][device] = {}
        allow(node).to receive(:device_of_mount).with('/').and_return(
          "/dev/#{device}",
        )
        expect(FB::Storage.root_device_name(node)).to eq(device)
      end
    end
  end

  context '#partition_device_name' do
    it 'should insert a p when the device name ends in a number' do
      FB::Storage.partition_device_name('abcd0', 2).
        should eq('abcd0p2')
    end
    it 'should not insert a p when the device name ends in a number' do
      FB::Storage.partition_device_name('abcd', 2).
        should eq('abcd2')
    end
  end

  context '#device_name_from_partition' do
    it 'should handle devices that end in digits' do
      {
        '/dev/md0p1' => '/dev/md0',
        '/dev/nvme0n1p0' => '/dev/nvme0n1',
        '/dev/nvme1n2p1' => '/dev/nvme1n2',
        '/dev/something0p0' => '/dev/something0',
      }.each do |part, dev|
        expect(FB::Storage.device_name_from_partition(part)).
          to eq(dev)
      end
    end

    # see comment in the code for why this is necessary
    it 'should handle devices that end in digits, even when handed' +
      ' non-partitions' do
      {
        '/dev/md0' => '/dev/md0',
        '/dev/nvme0n1' => '/dev/nvme0n1',
      }.each do |part, dev|
        expect(FB::Storage.device_name_from_partition(part)).
          to eq(dev)
      end
    end

    it 'should handle devices that do not end in digits' do
      {
        '/dev/sda1' => '/dev/sda',
        '/dev/sdp1' => '/dev/sdp',
        '/dev/hdb4' => '/dev/hdb',
        '/dev/sdab9' => '/dev/sdab',
        '/dev/fioa2' => '/dev/fioa',
      }.each do |part, dev|
        expect(FB::Storage.device_name_from_partition(part)).
          to eq(dev)
      end
    end
  end

  context '#block_device_split' do
    it 'splits correctly for valid inputs' do
      {
        'sda' => ['sd', 'a'],
        'sdc' => ['sd', 'c'],
        'sdaa' => ['sd', 'aa'],
        'sdac' => ['sd', 'ac'],
        'fioa' => ['fio', 'a'],
        'fioc' => ['fio', 'c'],
        'nvme0n1' => ['nvme', '0n1'],
        'nvme1n4' => ['nvme', '1n4'],
        'nvme10n24' => ['nvme', '10n24'],
        'nbd3' => ['nbd', '3'],
        'nbd12' => ['nbd', '12'],
      }.each do |input, output|
        expect(FB::Storage.block_device_split(input)).to eq(output)
      end
    end

    it 'throws errors on invalid inputs' do
      [
        'hda',
        'hdaa',
        'fda',
        'hda1',
        'hda3',
        # valid devices with a partition, which is invalid
        'sda2',
        'fioa1',
        'nvme0n1p3',
        'nbd2p2',
      ].each do |badinput|
        expect do
          FB::Storage.block_device_split(badinput)
        end.to raise_error(RuntimeError)
      end
    end
  end

  context '#block_device_sort' do
    # normal sorting
    it 'sorts sdb before sdc' do
      expect(FB::Storage.block_device_sort('sdb', 'sdc', {})).
        to eq(-1)
    end

    # b < aa
    it 'sorts sdb before sdaa' do
      expect(FB::Storage.block_device_sort('sdb', 'sdaa', {})).
        to eq(-1)
    end

    it 'does not sort fioa between sdz and sdaa' do
      expect(
        ['sdz', 'fioa', 'sdaa'].sort do |a, b|
          FB::Storage.block_device_sort(a, b, {})
        end,
      ).to eq(['sdz', 'sdaa', 'fioa'])
    end

    it 'sorts nvme by card number then namespace number' do
      expect(
        [
          'nvme2n2', 'nvme1n2', 'nvme2n4', 'nvme22n1', 'nvme0n22', 'nvme0n2'
        ].sort do |a, b|
          FB::Storage.block_device_sort(a, b, {})
        end,
      ).to eq(
        ['nvme0n2', 'nvme0n22', 'nvme1n2', 'nvme2n2', 'nvme2n4', 'nvme22n1'],
      )
    end

    it 'sorts prefixes together' do
      # prefixes by length: sd, fio, nvme
      expect(
        [
          'sdac', 'sdq', 'fiob', 'nvme1n1', 'sdb', 'fioa', 'sdaa', 'nvme0n1'
        ].sort do |a, b|
          FB::Storage.block_device_sort(a, b, {})
        end,
      ).to eq(
        ['sdb', 'sdq', 'sdaa', 'sdac', 'fioa', 'fiob', 'nvme0n1', 'nvme1n1'],
      )
    end
  end

  context '#hybrid_xfs_md_part_size' do
    num_sectors_256gb = 500118192
    num_sectors_1tb = 1758174768
    it 'should return size divided by num_fses with sectors_reserved=0' do
      allow(FB::Storage).to receive(
        :hybrid_md_idx_size,
      ).and_return(num_sectors_256gb)
      size = FB::Storage.hybrid_xfs_md_part_size(node, 0, 36)
      expect(size).to eq(6783) # in MiB
    end
    it 'should subtract sectors_reserved when provided and then divide' do
      allow(FB::Storage).to receive(
        :hybrid_md_idx_size,
      ).and_return(num_sectors_1tb)
      size = FB::Storage.hybrid_xfs_md_part_size(
        node, 0, 36, num_sectors_256gb
      )
      expect(size).to eq(17063) # in MiB
    end
  end

  context '#sort_scsi_slots' do
    it 'should sort, by column, numerically' do
      expect(
        [
          '0:2:3:0',
          '1:0:0:91',
          '5:01:00:1',
          '0:12:3:0',
          '5:10:00:9',
          '5:9:9:19',
        ].sort do |a, b|
          FB::Storage.sort_scsi_slots(a, b)
        end,
      ).to eq(
        [
          '0:2:3:0',
          '0:12:3:0',
          '1:0:0:91',
          '5:01:00:1',
          '5:9:9:19',
          '5:10:00:9',
        ],
      )
    end
  end

  context '#scsi_device_sort' do
    let(:mapping) do
      {
        '/dev/sdc' => '0:2:3:0',
        '/dev/sdq' => '1:0:0:91',
      }
    end

    it 'should sort SCSI before non-SCSI' do
      expect(
        FB::Storage.scsi_device_sort(
          '/dev/sdb',
          '/dev/sdc',
          mapping,
        ),
      ).to eq(1)
    end

    it 'should sort non-SCSI after SCSI' do
      expect(
        FB::Storage.scsi_device_sort(
          '/dev/sdc',
          '/dev/sdb',
          mapping,
        ),
      ).to eq(-1)
    end

    it 'should treat two non-SCSI as equal' do
      expect(
        FB::Storage.scsi_device_sort(
          '/dev/sdx',
          '/dev/sdz',
          mapping,
        ),
      ).to eq(0)
    end
  end

  context '#sort_disk_shelves' do
    it 'should sort shelves by shelf number then disk number' do
      expect(
        [
          {
            'shelf' => '/dev/bsg/6:0:4:0',
            'disk' => 0,
          },
          {
            'shelf' => '/dev/bsg/6:0:31:0',
            'disk' => 0,
          },
          {
            'shelf' => '/dev/bsg/6:1:0:0',
            'disk' => 3,
          },
          {
            'shelf' => '/dev/bsg/6:1:0:0',
            'disk' => 9,
          },
          {
            'shelf' => '/dev/bsg/6:0:31:0',
            'disk' => 2,
          },
          {
            'shelf' => '/dev/bsg/6:0:4:0',
            'disk' => 1,
          },
        ].sort do |a, b|
          FB::Storage.sort_disk_shelves(a, b)
        end,
      ).to eq([
        # in particular we want to make sure 4 < 31
        {
          'shelf' => '/dev/bsg/6:0:4:0',
          'disk' => 0,
        },
        {
          'shelf' => '/dev/bsg/6:0:4:0',
          'disk' => 1,
        },
        {
          'shelf' => '/dev/bsg/6:0:31:0',
          'disk' => 0,
        },
        {
          'shelf' => '/dev/bsg/6:0:31:0',
          'disk' => 2,
        },
        {
          'shelf' => '/dev/bsg/6:1:0:0',
          'disk' => 3,
        },
        {
          'shelf' => '/dev/bsg/6:1:0:0',
          'disk' => 9,
        },
      ])
    end
  end

  context '#load_previous_disk_order' do
    it 'reads v1 files correctly' do
      allow(File).to receive(:size?).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(100)
      allow(File).to receive(:read).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(
        '["sdl","sdr","sdy","sdb","sdc","sdt"]',
      )
      ret = FB::Storage.load_previous_disk_order
      expect(ret).to eq(['sdl', 'sdr', 'sdy', 'sdb', 'sdc', 'sdt'])
    end
  end

  context '#load_previous_disk_order' do
    it 'reads v2 files correctly' do
      mapping = {
        'xxx' => 'sdl',
        'aaa' => 'sdr',
        'bbb' => 'sdy',
        'ccc' => 'sdb',
        'ddd' => 'sdc',
        'eee' => 'sdt',
      }
      allow(File).to receive(:size?).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(100)
      allow(File).to receive(:read).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(
        '{"version":2,"disks":["xxx","aaa","bbb","ccc","ddd","eee"]}',
      )
      mapping.each do |id, dev|
        sys = "#{FB::Storage::DEV_ID_DIR}/#{id}"
        allow(File).to receive(:exist?).with(sys).and_return(dev)
        allow(File).to receive(:readlink).with(sys).and_return("/dev/#{dev}")
      end
      ret = FB::Storage.load_previous_disk_order
      expect(ret).to eq(['sdl', 'sdr', 'sdy', 'sdb', 'sdc', 'sdt'])
    end

    it 'does not accept other formats' do
      allow(File).to receive(:size?).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(100)
      allow(File).to receive(:read).with(
        FB::Storage::PREVIOUS_DISK_ORDER,
      ).and_return(
        '{"version":3,"disks":{}}',
      )
      expect do
        FB::Storage.load_previous_disk_order
      end.to raise_error(RuntimeError)
    end
  end

  context '#gen_persistent_disk_data' do
    it 'writes v2 format' do
      mapping = {
        'xxx' => 'sdl',
        'aaa' => 'sdr',
        'bbb' => 'sdy',
        'ccc' => 'sdb',
        'ddd' => 'sdc',
        'eee' => 'sdt',
      }
      allow(Dir).to receive(:open).with(
        FB::Storage::DEV_ID_DIR,
      ).and_return(mapping.keys)
      mapping.each do |k, v|
        allow(File).to receive(:readlink).with(
          "#{FB::Storage::DEV_ID_DIR}/#{k}",
        ).and_return("/dev/#{v}")
      end
      expected = {
        'version' => 2,
        'disks' => mapping.keys,
      }
      ret = FB::Storage.gen_persistent_disk_data(mapping.values)
      expect(ret).to eq(expected)
    end
  end

  context '#calculate_updated_order' do
    it 'slots new disks into old slots' do
      [
        # simple example: replacing 'b' with 'f'
        {
          'previous' => ['a', 'b', 'c', 'd', 'e'],
          'new' => ['a', 'c', 'd', 'e', 'f'],
          'expected' => ['a', 'f', 'c', 'd', 'e'],
        },
        # slightly more complicated
        # replacing 'b' with 'f' and 'd' with 'g'
        {
          'previous' => ['a', 'b', 'c', 'd', 'e'],
          'new' => ['a', 'c', 'e', 'f', 'g'],
          'expected' => ['a', 'f', 'c', 'g', 'e'],
        },
        # more complicated example. like the above, but the new ordering
        # is different from expected, g and f ordered differently (for SCSI slot
        # or JBOD slot). So... 'b' is now 'g' and 'd' is now 'f'
        {
          'previous' => ['a', 'b', 'c', 'd', 'e'],
          'new' => ['a', 'c', 'e', 'g', 'f'],
          'expected' => ['a', 'g', 'c', 'f', 'e'],
        },
        # another complicated example. like the above, but the both orderings
        # are unexpected - 'e' replaced by 'q' and 'c' replaced with 'l'
        {
          'previous' => ['d', 'e', 'a', 'f', 'c'],
          'new' => ['d', 'a', 'f', 'q', 'l'],
          'expected' => ['d', 'q', 'a', 'f', 'l'],
        },
        # most complicated example... we totally changed our algorithm and
        # fucked everything up so all the ordering is different, but only one
        # disk changed. We should ignore the new algorithm and keep things
        # as they are except for 'c' -> 'l'
        {
          'previous' => ['a', 'b', 'c', 'd', 'e'],
          'new' => ['d', 'a', 'e', 'l', 'b'],
          'expected' => ['a', 'b', 'l', 'd', 'e'],
        },
      ].each do |example|
        ret = FB::Storage.calculate_updated_order(
          example['previous'],
          example['new'],
        )
        expect(ret).to eq(example['expected'])
      end
    end
    it 'fails when new and old are the same disks' do
      disks = ['b', 'a', 'd', 'e', 'c']
      expect do
        FB::Storage.calculate_updated_order(disks, disks.sort)
      end.to raise_error(RuntimeError)
    end
  end

  context '#sorted_devices' do
    before do
      allow(node).to receive(:device_of_mount).and_return('/dev/sda')
      allow(node).to receive(:virtual?).and_return(false)
      allow(FB::Storage).to receive(:write_out_disk_order).
        and_return(nil)
    end
    before(:each) do
      node.default['fb_storage']['_ordered_disks'] = nil
    end
    context 'with a cache file' do
      it 'should use the cache file when all disks are in the same order' do
        previous_order = ['b', 'e', 'd', 'a', 'c']
        expect(FB::Storage).to receive(:load_previous_disk_order).
          and_return(previous_order)
        expect(FB::Storage).to receive(:eligible_devices).
          and_return(previous_order)
        expect(Chef::Log).to receive(:debug).with(/Using previous/)
        expect(FB::Storage.sorted_devices(node, [])).to eq(
          previous_order,
        )
      end

      it 'should use the cache file when all disks are in a different order' do
        previous_order = ['b', 'e', 'd', 'a', 'c']
        expect(FB::Storage).to receive(:load_previous_disk_order).
          and_return(previous_order)
        expect(FB::Storage).to receive(:eligible_devices).
          and_return(['a', 'b', 'c', 'd', 'e'])
        expect(Chef::Log).to receive(:debug).with(/Using previous/)
        expect(FB::Storage.sorted_devices(node, [])).to eq(
          previous_order,
        )
      end

      it 'should base the new order on the old order when disks change' do
        # for can_use_dev_id?
        node.automatic['block_device'] = {}

        previous_order = ['sdb', 'sde', 'sdd', 'sdc', 'sdf']
        expect(FB::Storage).to receive(:load_previous_disk_order).
          and_return(previous_order)
        expect(FB::Storage).to receive(:eligible_devices).
          and_return(['sdf', 'sdb', 'sdd', 'sde', 'sdg'])
        expect(Chef::Log).not_to receive(:debug).with(/Using previous/)
        expect(FB::Storage.sorted_devices(node, [])).to eq(
          # only sdc was replaced (with sdg)
          ['sdb', 'sde', 'sdd', 'sdg', 'sdf'],
        )
      end
    end
  end

  context '#_handle_custom_device_order_method' do
    context 'with a _clowntown_device_order_method' do
      before(:each) do
        node.default['fb_storage'][
          '_clowntown_device_order_method'] = double('custom_device_order')
        allow(FB::Storage).to receive(
          :write_out_disk_order,
        ).and_return(true)
      end
      it 'should call the custom method if firstboot' do
        allow(node).to receive(:firstboot_tier?).and_return(true)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(false)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).to receive(:call).once
        FB::Storage._handle_custom_device_order_method(node)
      end
      it 'should call the custom method if signal file exists (and delete ' +
          'signal file)' do
        allow(node).to receive(:firstboot_tier?).and_return(false)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(true)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).to receive(:call).once
        expect(File).to receive(:delete).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        )
        FB::Storage._handle_custom_device_order_method(node)
      end
      it 'should call the custom method if firstboot and signal file exists' +
          ' (and delete signal file)' do
        allow(node).to receive(:firstboot_tier?).and_return(true)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(true)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).to receive(:call).once
        expect(File).to receive(:delete).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        )
        FB::Storage._handle_custom_device_order_method(node)
      end
      it 'should not call the custom method if not firstboot or signal file' do
        allow(node).to receive(:firstboot_tier?).and_return(false)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(false)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).not_to receive(:call)
        FB::Storage._handle_custom_device_order_method(node)
      end
    end
    context 'without a _clowntown_device_order_method' do
      before(:each) do
        node.default['fb_storage'][
          '_clowntown_device_order_method'] = nil
      end
      it 'should not call the method if firstboot' do
        allow(node).to receive(:firstboot_tier?).and_return(true)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(false)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).not_to receive(:call)
        FB::Storage._handle_custom_device_order_method(node)
      end
      it 'should not call the method if signal file (and delete file)' do
        allow(node).to receive(:firstboot_tier?).and_return(false)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(true)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).not_to receive(:call)
        FB::Storage._handle_custom_device_order_method(node)
      end
      it 'should not call the method if neither first boot nor signal file ' +
          '(and delete the file)' do
        allow(node).to receive(:firstboot_tier?).and_return(false)
        allow(File).to receive(:exist?).with(
          FB::Storage::FORCE_WRITE_CUSTOM_DISK_ORDER,
        ).and_return(false)
        expect(
          node['fb_storage']['_clowntown_device_order_method'],
        ).not_to receive(:call)
        FB::Storage._handle_custom_device_order_method(node)
      end
    end
  end

  context '#build_mapping' do
    before do
      allow(node).to receive(:device_of_mount).and_return('/dev/sda')
      allow(node).to receive(:virtual?).and_return(false)
      allow(FB::Storage).to receive(:load_previous_disk_order).
        and_return(nil)
      allow(FB::Storage).to receive(:write_out_disk_order).
        and_return(nil)
    end

    context 'straight disks' do
      6.times.each do |i|
        let("device#{i + 1}".to_sym) do
          {
            'partitions' => [
              {
                'type' => 'xfs',
                'mount_point' => "/data/#{i + 1}",
                'opts' => 'default',
                'pass' => 2,
                'enable_remount' => true,
              },
            ],
          }
        end
      end
      it 'should build config in consistent order for local storage' do
        node.default['fb_storage']['devices'] = [device1, device2]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'fioa' => {},
        }
        node.automatic['fb'] = {}
        expected = {
          :disks => {
            '/dev/sdb' => device1,
            '/dev/fioa' => device2,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)

        # same thing, but if `block_device` reports a different order
        node.automatic['block_device'] = {
          'fioa' => {},
          'sda' => {},
          'sdb' => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build config in consistent order for shelves' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4, device5, device6
        ]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'sdc' => {},
          'sdd' => {},
          'sdl' => {},
          'sdn' => {},
          'sdq' => {},
        }
        node.automatic['fb']['fbjbod']['shelves']['/dev/bsg/6:0:31:0'] = [
          '/dev/sdb', '/dev/sdd', '/dev/sdc'
        ]
        node.automatic['fb']['fbjbod']['shelves']['/dev/bsg/6:0:15:0'] = [
          '/dev/sdq', '/dev/sdl', '/dev/sdn'
        ]

        expected = {
          :disks => {
            '/dev/sdq' => device1,
            '/dev/sdl' => device2,
            '/dev/sdn' => device3,
            '/dev/sdb' => device4,
            '/dev/sdd' => device5,
            '/dev/sdc' => device6,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'handles back-compat shelf names' do
        node.default['fb_storage']['devices'] = [
          device1, device2
        ]
        node.automatic['fb']['fbjbod']['shelves']['/dev/sg14'] = [
          '/dev/sdb',
        ]
        node.automatic['fb']['fbjbod']['shelves']['/dev/sg2'] = [
          '/dev/sdq',
        ]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'sdq' => {},
        }
        expected = {
          :disks => {
            '/dev/sdq' => device1,
            '/dev/sdb' => device2,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build config in consistent order for shelves+flash' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4
        ]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {}, # fbjbod
          'sdc' => {}, # lsicard
          'sdd' => {}, # fbjbod
          'fioa' => {}, # fio card
        }
        node.automatic['fb']['fbjbod']['shelves']['/dev/sg16'] = [
          '/dev/sdd', '/dev/sdb'
        ]

        expected = {
          :disks => {
            # local attached first
            '/dev/sdc' => device1,
            '/dev/fioa' => device2,
            # then shelves, in shelf order
            '/dev/sdd' => device3,
            '/dev/sdb' => device4,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build config in consistent order for scsi slots' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3
        ]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'sdc' => {},
          'sdd' => {},
        }
        node.automatic['scsi'] = {
          '1:2:3:4' => {
            'device' => '/dev/sda',
          },
          '0:99:1:2' => {
            'device' => '/dev/sdb',
          },
          '9:1:6:5' => {
            'device' => '/dev/sdc',
          },
          '0:9:1:2' => {
            'device' => '/dev/sdd',
          },
        }

        expected = {
          :disks => {
            # in order of SCSI bus
            '/dev/sdd' => device1,
            '/dev/sdb' => device2,
            '/dev/sdc' => device3,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build config in consistent order for jbod+scsi+disks' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4, device5, device6
        ]
        node.automatic['block_device'] = {
          'sda' => {}, # root
          'sdb' => {}, # jbod
          'sdc' => {}, # scsi
          'sdd' => {}, # jbod
          'fioa' => {}, # flash
          'sde' => {}, # drive w/out SCSI addr
          'sdf' => {}, # scsi
        }
        node.automatic['scsi'] = {
          '1:2:3:4' => {
            'device' => '/dev/sda',
          },
          '9:12:6:5' => {
            'device' => '/dev/sdc',
          },
          '9:1:6:5' => {
            'device' => '/dev/sdf',
          },
        }
        node.automatic['fb']['fbjbod']['shelves']['/dev/sg16'] = [
          '/dev/sdd', '/dev/sdb'
        ]

        expected = {
          :disks => {
            # in order of SCSI bus
            '/dev/sdf' => device1,
            '/dev/sdc' => device2,
            # now leftover disk
            '/dev/sde' => device3,
            '/dev/fioa' => device4,
            # now jbod
            '/dev/sdd' => device5,
            '/dev/sdb' => device6,
          },
          :arrays => {},
        }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end
    end

    context 'arrays' do
      3.times.each do |array|
        5.times.each do |device|
          let("device#{(array * 5) + device + 1}".to_sym) do
            {
              'partitions' => [
                {
                  '_swraid_array' => array,
                },
              ],
            }
          end
        end
        let("array#{array + 1}".to_sym) do
          {
            'type' => 'xfs',
            'mount_point' => "/data/#{array + 1}",
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
            'raid_level' => 5,
          }
        end
      end

      it 'should build a config with single array mapping' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4, device5
        ]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'sdc' => {},
          'sdd' => {},
          'sde' => {},
          'sdf' => {},
        }
        expected_disks = {
          '/dev/sdb' => device1,
          '/dev/sdc' => device2,
          '/dev/sdd' => device3,
          '/dev/sde' => device4,
          '/dev/sdf' => device5,
        }
        expected_arrays = {
          '/dev/md0' => array1.merge(
            { 'members' => expected_disks.keys.map { |x| "#{x}1" } },
          ),
        }
        expected = { :disks => expected_disks, :arrays => expected_arrays }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build a config with multiple array mapping' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4, device5,
          device6, device7, device8, device9, device10,
          device11, device12, device13, device14, device15
        ]
        node.default['fb_storage']['arrays'] = [
          array1, array2, array3
        ]
        expected_disks = {
          '/dev/sdb' => device1,
          '/dev/sdc' => device2,
          '/dev/sdd' => device3,
          '/dev/sde' => device4,
          '/dev/sdf' => device5,
          '/dev/sdg' => device6,
          '/dev/sdh' => device7,
          '/dev/sdi' => device8,
          '/dev/sdj' => device9,
          '/dev/sdk' => device10,
          '/dev/sdl' => device11,
          '/dev/sdm' => device12,
          '/dev/sdn' => device13,
          '/dev/sdo' => device15,
          '/dev/sdp' => device15,
        }
        expected_disks.each_key do |d|
          node.automatic['block_device'][File.basename(d)] = {}
        end
        node.automatic['block_device']['sda'] = {}
        expected_arrays = {
          '/dev/md0' => array1.merge(
            { 'members' => expected_disks.keys[0..4].map { |x| "#{x}1" } },
          ),
          '/dev/md1' => array2.merge(
            { 'members' => expected_disks.keys[5..9].map { |x| "#{x}1" } },
          ),
          '/dev/md2' => array3.merge(
            { 'members' => expected_disks.keys[10..14].map { |x| "#{x}1" } },
          ),
        }
        expected = { :disks => expected_disks, :arrays => expected_arrays }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end

      it 'should build a config with multiple array mapping, ' +
         'and a skipped array' do
        node.default['fb_storage']['devices'] = [
          { '_skip' => true }, { '_skip' => true }, { '_skip' => true },
          { '_skip' => true }, { '_skip' => true },
          device6, device7, device8, device9, device10,
          device11, device12, device13, device14, device15
        ]
        node.default['fb_storage']['arrays'] = [
          { '_skip' => true }, array2, array3
        ]
        expected_disks = {
          '/dev/sdb' => { '_skip' => true },
          '/dev/sdc' => { '_skip' => true },
          '/dev/sdd' => { '_skip' => true },
          '/dev/sde' => { '_skip' => true },
          '/dev/sdf' => { '_skip' => true },
          '/dev/sdg' => device6,
          '/dev/sdh' => device7,
          '/dev/sdi' => device8,
          '/dev/sdj' => device9,
          '/dev/sdk' => device10,
          '/dev/sdl' => device11,
          '/dev/sdm' => device12,
          '/dev/sdn' => device13,
          '/dev/sdo' => device15,
          '/dev/sdp' => device15,
        }
        expected_disks.each_key do |d|
          node.automatic['block_device'][File.basename(d)] = {}
        end
        node.automatic['block_device']['sda'] = {}
        expected_arrays = {
          '/dev/md0' => { '_skip' => true, 'members' => [] },
          '/dev/md1' => array2.merge(
            { 'members' => expected_disks.keys[5..9].map { |x| "#{x}1" } },
          ),
          '/dev/md2' => array3.merge(
            { 'members' => expected_disks.keys[10..14].map { |x| "#{x}1" } },
          ),
        }
        expected = { :disks => expected_disks, :arrays => expected_arrays }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end
    end

    context 'hybrid_xfs arrays' do
      let('device1'.to_sym) do
        {
          'partitions' => 3.times.map do |i|
            {
              '_xfs_rt_metadata' => i,
            }
          end,
        }
      end
      3.times.each do |i|
        let("device#{i + 2}".to_sym) do
          {
            'partitions' => [
              {
                '_xfs_rt_data' => i,
              },
            ],
          }
        end
        let("array#{i + 1}".to_sym) do
          {
            'type' => 'xfs',
            'mount_point' => "/data/#{i + 1}",
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
            'raid_level' => 'hybrid_xfs',
          }
        end
      end

      it 'should build a config with hybrid_xfs mapping' do
        node.default['fb_storage']['devices'] = [
          device1, device2, device3, device4
        ]
        node.default['fb_storage']['arrays'] = [
          array1, array2, array3
        ]
        node.automatic['block_device'] = {
          'sda' => {},
          'sdb' => {},
          'sdc' => {},
          'sdd' => {},
          'sde' => {},
        }
        expected_disks = {
          '/dev/sdb' => device1,
          '/dev/sdc' => device2,
          '/dev/sdd' => device3,
          '/dev/sde' => device4,
        }
        %w{sdc sdd sde}.each_with_index do |d, idx|
          expected_disks["/dev/#{d}"]['partitions'][0]['part_name'] =
            "/data/#{idx + 1}"
        end
        3.times.map do |i|
          expected_disks['/dev/sdb']['partitions'][i]['part_name'] =
            "md:/data/#{i + 1}"
        end
        node.automatic['block_device']['sda'] = {}
        expected_arrays = {
          '/dev/md0' => array1.merge(
            {
              'members' => ['/dev/sdc1'],
              'journal' => '/dev/sdb1',
            },
          ),
          '/dev/md1' => array2.merge(
            {
              'members' => ['/dev/sdd1'],
              'journal' => '/dev/sdb2',
            },
          ),
          '/dev/md2' => array3.merge(
            {
              'members' => ['/dev/sde1'],
              'journal' => '/dev/sdb3',
            },
          ),
        }
        expected = { :disks => expected_disks, :arrays => expected_arrays }
        expect(FB::Storage.build_mapping(node, [])).to eq(expected)
      end
    end
  end

  context '#partition_names' do
    it 'should list all configured partitions for a device' do
      device1 = {
        'partitions' => [
          {
            'type' => 'xfs',
            'mount_point' => '/data/1',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
        ],
      }
      device2 = {
        'partitions' => [
          {
            'type' => 'xfs',
            'mount_point' => '/waka/1',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
          {
            'type' => 'xfs',
            'mount_point' => '/waka/2',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
          {
            'type' => 'xfs',
            'mount_point' => '/waka/3',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
        ],
      }

      FB::Storage.partition_names('/dev/fioa', device1).
        should eq(['/dev/fioa1'])

      FB::Storage.partition_names('/dev/fioa', device2).
        should eq(['/dev/fioa1', '/dev/fioa2', '/dev/fioa3'])
    end
  end

  context 'common device needs' do
    let(:single_partition_device) do
      {
        'partitions' => [
          {
            'type' => 'xfs',
            'mount_point' => '/data/fa',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
            'label' => '/data/fa',
          },
        ],
      }
    end

    let(:double_partition_device) do
      {
        'partitions' => [
          {
            'type' => 'xfs',
            'mount_point' => '/data/fa2',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
          {
            'type' => 'xfs',
            'mount_point' => '/data/fa3',
            'opts' => 'default',
            'pass' => 2,
            'enable_remount' => true,
          },
        ],
      }
    end

    let(:single_array) do
      {
        'type' => 'xfs',
        'mount_point' => '/data/fa',
        'opts' => 'default',
        'pass' => 2,
        'enable_remount' => true,
        'raid_level' => 1,
      }
    end

    let(:array_member) do
      {
        'partitions' => [
          {
            '_swraid_array' => 0,
          },
        ],
      }
    end

    let(:whole_device_single_fs) do
      {
        'whole_device' => true,
        'partitions' => [{
          'type' => 'xfs',
          'mount_point' => '/data/fa',
          'opts' => 'default',
          'pass' => 2,
          'enable_remount' => true,
          'label' => '/data/fa',
        }],
      }
    end

    context '#out_of_spec' do
      before do
        allow(FB::Storage).to receive(:get_actual_part_name).and_return(
          nil, # ''
        )
      end
      it 'should return nothing if everything is in spec' do
        node.default['fb_storage']['devices'] = [
          single_partition_device, double_partition_device,
          whole_device_single_fs
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb1' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
            'label' => '/data/fa',
          },
          '/dev/sdc1' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
          },
          '/dev/sdc2' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
          },
          '/dev/sdd' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
            'label' => '/data/fa',
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => single_partition_device,
              '/dev/sdc' => double_partition_device,
            },
            :arrays => {},
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched filesystems' do
        node.default['fb_storage']['devices'] = [
          single_partition_device,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb1' => {
            'fs_type' => 'ext4',
            'mounts' => ['/data/fa'],
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => single_partition_device }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/sdb1'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched partitions' do
        node.default['fb_storage']['devices'] = [
          single_partition_device,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb1' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
          },
          '/dev/sdb2' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => single_partition_device }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => ['/dev/sdb'],
            :mismatched_filesystems => ['/dev/sdb1'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify missing partitions' do
        node.default['fb_storage']['devices'] = [
          double_partition_device,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => double_partition_device }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => ['/dev/sdb'],
            :missing_filesystems => ['/dev/sdb1', '/dev/sdb2'],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched labels on a partition' do
        node.default['fb_storage']['devices'] = [
          single_partition_device,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb1' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
            'label' => '/wrong_label',
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => single_partition_device }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/sdb1'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify wrong partlabel on hybrid metadata device' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'wrong_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'correct_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => ['/dev/sdb'],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should not consider hybrid md out of spec when partlabel correct' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'correct_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should flag wrong xfs label on hybrid md device as out of spec' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'correct_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs', 'label' => '/wrong_label' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'],
                  'journal' => '/dev/sdb1',
                  'label' => '/data/fa' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/md0', '/dev/sdb1'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should not flag a hybrid xfs md partition with the correct label' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'correct_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs', 'label' => '/data/fa' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'],
                  'journal' => '/dev/sdb1',
                  'label' => '/data/fa' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched partlabels for hybrid FS' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'wrong_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => ['/dev/sdc'],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'it should match correct partlabels for hybrid FS' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
              'part_name' => 'correct_part_name',
            },
            {
              '_xfs_rt_rescue' => 0,
              'part_name' => 'correct_part_name',
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
          '/dev/sdc2' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        expect(FB::Storage).to receive(:get_actual_part_name).and_return(
          'correct_part_name',
        ).exactly(3).times
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched labels on a whole device' do
        node.default['fb_storage']['devices'] = [
          whole_device_single_fs,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {
            'fs_type' => 'xfs',
            'mounts' => ['/data/fa'],
            'label' => '/wrong_label',
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => whole_device_single_fs }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        puts(storage.out_of_spec)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/sdb'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify missing arrays' do
        node.default['fb_storage']['devices'] = [
          array_member, array_member
        ]
        node.default['fb_storage']['arrays'] = [single_array]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdc' => {},
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => array_member, '/dev/sdc' => array_member
            },
            :arrays => { '/dev/md0' => single_array },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/md0'],
            :mismatched_arrays => [],
            :missing_partitions => ['/dev/sdb', '/dev/sdc'],
            :missing_filesystems => ['/dev/sdb1', '/dev/sdc1'],
            :missing_arrays => ['/dev/md0'],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify mismatched arrays' do
        device1 = {
          '_skip' => true,
        }
        node.default['fb_storage']['devices'] = [
          device1, array_member, array_member
        ]
        node.default['fb_storage']['arrays'] = [single_array]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdc' => {},
          '/dev/sdd' => {},
          '/dev/md0' => { 'fs_type' => 'xfs' },
        }
        node.automatic['mdadm']['md0'] = {
          'level' => 1,
          'members' => ['sdb1', 'sdc1'],
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => device1,
              '/dev/sdc' => array_member,
              '/dev/sdd' => array_member,
            },
            :arrays => {
              '/dev/md0' => single_array.merge(
                { 'members' => ['/dev/sdc1', '/dev/sdd1'] },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/md0'],
            :mismatched_arrays => ['/dev/md0'],
            :missing_partitions => ['/dev/sdc', '/dev/sdd'],
            :missing_filesystems => ['/dev/sdc1', '/dev/sdd1'],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'should identify arrays with missing members' do
        node.default['fb_storage']['devices'] = [
          array_member, array_member
        ]
        node.default['fb_storage']['arrays'] = [single_array]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdc' => {},
          '/dev/md0' => { 'fs_type' => 'xfs' },
        }
        node.automatic['mdadm']['md0'] = {
          'level' => 1,
          'members' => ['sdb1'],
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => array_member, '/dev/sdc' => array_member
            },
            :arrays => {
              '/dev/md0' => single_array.merge(
                { 'members' => ['/dev/sdb1', '/dev/sdc1'] },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => ['/dev/sdb', '/dev/sdc'],
            :missing_filesystems => ['/dev/sdb1', '/dev/sdc1'],
            :missing_arrays => [],
            :incomplete_arrays => { '/dev/md0' => ['/dev/sdc1'] },
            :extra_arrays => [],
          },
        )
      end

      it 'should identify extra arrays' do
        device1 = {
          'partitions' => [
            {
              '_swraid_array' => 0,
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_swraid_array' => 0,
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'mount_point' => '/data/fa',
          'opts' => 'default',
          'pass' => 2,
          'enable_remount' => true,
          'raid_level' => 1,
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => { 'fs_type' => 'xfs' },
          '/dev/md0' => { 'fs_type' => 'xfs' },
        }
        node.automatic['mdadm'] = {
          'md0' => {
            'level' => 1,
            'members' => ['sdb1', 'sdc1'],
          },
          'md1' => {
            'level' => 6,
            'members' => ['whatever'],
          },
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdb1', '/dev/sdc1'] },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => ['/dev/md1'],
          },
        )
      end

      it 'it match hybrid_xfs metadata as xfs for matched FS' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'xfs' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'matches hybrid_xfs metadata as xfs for mismatched FSes' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => { 'fs_type' => 'ext4' },
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => ['/dev/md0', '/dev/sdb1'],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => [],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end

      it 'matches hybrid_xfs metadata as xfs for missing FSes' do
        device1 = {
          'partitions' => [
            {
              '_xfs_rt_metadata' => 0,
            },
          ],
        }
        device2 = {
          'partitions' => [
            {
              '_xfs_rt_data' => 0,
            },
          ],
        }
        array1 = {
          'type' => 'xfs',
          'raid_level' => 'hybrid_xfs',
          'mount_point' => '/data/fa',
        }
        node.default['fb_storage']['devices'] = [device1, device2]
        node.default['fb_storage']['arrays'] = [array1]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdb1' => {},
          '/dev/sdc' => {},
          '/dev/sdc1' => {},
        }
        node.automatic['mdadm'] = {}
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => device1, '/dev/sdc' => device2 },
            :arrays => {
              '/dev/md0' => array1.merge(
                { 'members' => ['/dev/sdc1'], 'journal' => '/dev/sdb1' },
              ),
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.out_of_spec).to eq(
          {
            :mismatched_partitions => [],
            :mismatched_filesystems => [],
            :mismatched_arrays => [],
            :missing_partitions => [],
            :missing_filesystems => ['/dev/md0', '/dev/sdb1'],
            :missing_arrays => [],
            :incomplete_arrays => {},
            :extra_arrays => [],
          },
        )
      end
    end

    context '#all_storage' do
      it 'should return all storage with one device' do
        node.default['fb_storage']['devices'] = [
          single_partition_device,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => { '/dev/sdb' => single_partition_device }, :arrays => {}
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.all_storage).to eq(
          {
            :devices => ['/dev/sdb'],
            :partitions => ['/dev/sdb1'],
            :arrays => [],
          },
        )
      end

      it 'should return all storage with many devices' do
        node.default['fb_storage']['devices'] = [
          single_partition_device, double_partition_device
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/fioa' => {},
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => single_partition_device,
              '/dev/fioa' => double_partition_device,
            },
            :arrays => {},
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.all_storage).to eq(
          {
            :devices => ['/dev/sdb', '/dev/fioa'],
            :partitions => ['/dev/sdb1', '/dev/fioa1', '/dev/fioa2'],
            :arrays => [],
          },
        )
      end

      it 'should return all storage with arrays' do
        node.default['fb_storage']['devices'] = [
          array_member, array_member
        ]
        node.default['fb_storage']['arrays'] = [single_array]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/fioa' => {},
          '/dev/md0' => { 'fs_type' => 'xfs' },
        }
        node.automatic['mdadm']['md0'] = {
          'level' => 1,
          'members' => ['sdb1', 'fioa1'],
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => array_member,
              '/dev/fioa' => array_member,
            },
            :arrays => { '/dev/md0' => single_array },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.all_storage).to eq(
          {
            :devices => ['/dev/sdb', '/dev/fioa'],
            :partitions => ['/dev/sdb1', '/dev/fioa1', '/dev/md0'],
            :arrays => ['/dev/md0'],
          },
        )
      end

      it 'should return all storage with arrays, skipping as necessary' do
        node.default['fb_storage']['devices'] = [
          { '_skip' => true }, { '_skip' => true },
          array_member, array_member
        ]
        node.default['fb_storage']['arrays'] = [
          { '_skip' => true },
          single_array,
        ]
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdb' => {},
          '/dev/sdc' => {},
          '/dev/sdd' => {},
          '/dev/sde' => {},
          '/dev/md0' => { 'fs_type' => 'ext4' },
          '/dev/md1' => { 'fs_type' => 'xfs' },
        }
        node.automatic['mdadm']['md0'] = {
          'level' => 1,
          'members' => ['sdb1', 'sdc1'],
        }
        node.automatic['mdadm']['md1'] = {
          'level' => 1,
          'members' => ['sdd1', 'sde1'],
        }
        expect(FB::Storage).to receive(:build_mapping).and_return(
          {
            :disks => {
              '/dev/sdb' => { '_skip' => true },
              '/dev/sdc' => { '_skip' => true },
              '/dev/sdd' => array_member,
              '/dev/sde' => array_member,
            },
            :arrays => {
              '/dev/md0' => { '_skip' => true },
              '/dev/md1' => single_array,
            },
          },
        )
        storage = FB::Storage.new(node)
        expect(storage.all_storage).to eq(
          {
            :devices => ['/dev/sdd', '/dev/sde'],
            :partitions => ['/dev/sdd1', '/dev/sde1', '/dev/md1'],
            :arrays => ['/dev/md1'],
          },
        )
      end
    end
  end

  context '#disks_from_automation' do
    it 'returns all disks from bar' do
      disks = ['sdb', 'fioa', '.', '..']
      allow(File).to receive(:directory?).with(
        FB::Storage::REPLACED_DISKS_DIR,
      ).and_return(true)
      allow(Dir).to receive(:new).and_return(disks)
      expect(FB::Storage.disks_from_automation).
        to eq(['/dev/sdb', '/dev/fioa'])
    end
  end
end
