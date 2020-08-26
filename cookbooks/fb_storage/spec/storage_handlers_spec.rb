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
require_relative '../libraries/storage'
require_relative '../libraries/storage_handlers'

describe FB::Storage::Handler do
  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end

  before do
    # THIS IS VERY IMPORTANT!!! If we don't mock **every** call to
    # Mixlibh::ShellOut we can nuke the data on any machine that runs the unit
    # tests so we mock it to return BS, this ensures if we miss mocking a call
    # the tests fail rather than nuking the host
    allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).
      and_return(nil)
  end

  let(:mock_so) do
    double('shellout')
  end

  before(:each) do
    allow(mock_so).to receive(:run_command).and_return(mock_so)
    allow(mock_so).to receive(:error?).and_return(false)
    allow(mock_so).to receive(:stderr).and_return('')
  end

  class TestHandler < FB::Storage::Handler
    def initialize(device, node)
      super
      @type = :fake
    end
  end

  context 'Core API methods' do
    before do
      # Similarly, all tests happen on sdzX to decrease any chance of
      # actually being related to real disks
      node.automatic[attr_name]['by_device'] = {
        '/dev/sda' => {},
        '/dev/sda1' => {},
        '/dev/sda2' => {},
        '/dev/sda3' => {},
        '/dev/sdzz' => {},
        '/dev/sdzz1' => {},
        '/dev/sdzx' => {},
        '/dev/sdzx1' => {},
        '/dev/sdzy' => {},
        '/dev/sdzy1' => {},
        '/dev/sdzw' => {},
        '/dev/sdzw1' => {},
      }
    end

    context '#remove_all_partitions_from_all_arrays' do
      it 'finds all conflicts' do
        sh = TestHandler.new('/dev/sdzz', node)

        expect(sh).to receive(:remove_from_arrays).with(
          ['/dev/sdzz1', '/dev/sdzz'],
        ).and_return(['/dev/sdzz1'])
        expect(sh).to receive(:nuke_raid_header).with('/dev/sdzz1').
          and_return(true)
        expect(sh).not_to receive(:nuke_raid_header).with('/dev/sdzz')
        sh.remove_all_partitions_from_all_arrays
      end
    end

    context '#wipe_device' do
      # technically the other tests all test this, but we if this fails
      # we want a test that fails before those that makes it clear
      # what's going on
      it 'attempts to unmount all partitions and remove them from arrays ' +
         'before doing work' do
        sh = TestHandler.new('/dev/nonexistent', node)
        expect(sh).to receive(:umount_all_partitions)
        expect(sh).to receive(:remove_all_partitions_from_all_arrays)
        sh.wipe_device
      end

      it 'removes all partitions when there is one' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/parted -s \'/dev/sdzz\' rm 1',
        ).and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:umount_all_partitions)
        expect(sh).to receive(:remove_all_partitions_from_all_arrays)
        sh.wipe_device
      end

      it 'removes all partitions where there are many' do
        4.times do |i|
          node.automatic[attr_name]['by_device']["/dev/sdzz#{i + 1}"] = {}
          expect(Mixlib::ShellOut).to receive(:new).with(
            "/sbin/parted -s '/dev/sdzz' rm #{i + 1}",
          ).and_return(mock_so)
        end
        sh = TestHandler.new('/dev/sdzz', node)
        # mock these calls which will be tested on their own
        expect(sh).to receive(:umount_all_partitions)
        expect(sh).to receive(:remove_all_partitions_from_all_arrays)
        sh.wipe_device
      end
    end

    context '#partition_device' do
      before(:each) do
        expect(mock_so).to receive(:error!).exactly(2).times
        expect(Mixlib::ShellOut).to receive(:new).with(
          "/sbin/parted -s '/dev/sdzz' mklabel gpt",
        ).and_return(mock_so)
        allow(File).to receive(:exist?).with('/dev/sdzz1').and_return(true)
      end

      let(:single) do
        { 'partitions' => [{}] }
      end

      let(:multiple) do
        {
          'partitions' => [
            {
              'partition_start' => '0%',
              'partition_end' => '50%',
            },
            {
              'partition_start' => '50%',
              'partition_end' => '100%',
            },
          ],
        }
      end

      it 'always makes a label' do
        # the real expectation for this test is the one in the `before`
        # this one is just to ignore the paritition making
        allow(Mixlib::ShellOut).to receive(:new).with(/parted/).
          and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        sh.partition_device(single)
      end

      it 'creates a single partition' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "/sbin/parted -s '/dev/sdzz' mkpart primary 0% 100% set 1 boot off",
        ).and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        sh.partition_device(single)
      end

      it 'handles multiple partitions' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "/sbin/parted -s '/dev/sdzz' " +
          'mkpart primary 0% 50% -a optimal set 1 boot off ' +
          'mkpart primary 50% 100% -a optimal set 2 boot off',
        ).and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        sh.partition_device(multiple)
      end

      it 'sets raid on for partition arrays' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          %r{parted -s '/dev/sdzz' .*set 2 raid on},
        ).and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        multiple['partitions'][1]['_swraid_array'] = 0
        sh.partition_device(multiple)
      end

      it 'sets partition labels' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          %r{parted -s '/dev/sdzz' .*name 1 poop},
        ).and_return(mock_so)
        sh = TestHandler.new('/dev/sdzz', node)
        multiple['partitions'][0]['part_name'] = 'poop'
        sh.partition_device(multiple)
      end
    end

    context '#format_partition' do
      context 'With successful mkfs' do
        before(:each) do
          expect(mock_so).to receive(:error!).once
        end

        # technically the other tests all test this, but we if this fails
        # we want a test that fails before those that makes it clear
        # what's going on
        it 'unmounts partition and removes it before doing anything' do
          expect(Mixlib::ShellOut).to receive(:new).and_return(mock_so)
          node.default['fb_storage'] = {}
          sh = TestHandler.new('/dev/sdzz', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          sh.format_partition(
            '/dev/sdzz1', { 'type' => 'xfs', 'label' => 'foo' }
          )
        end

        it 'calls mkfs on the right partition with the right fs type' do
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs .* /dev/sdzz1},
            { :timeout => 600 },
          ).and_return(mock_so)
          node.default['fb_storage'] = {}
          sh = TestHandler.new('/dev/sdzz', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          sh.format_partition(
            '/dev/sdzz1', { 'type' => 'xfs', 'label' => 'foo' }
          )
        end

        it 'truncates labels for XFS' do
          expect(Mixlib::ShellOut).to receive(:new).with(
            /-L "fooooooooooo"/,
            { :timeout => 600 },
          ).and_return(mock_so)
          node.default['fb_storage'] = {}
          sh = TestHandler.new('/dev/sdzz', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          sh.format_partition(
            '/dev/sdzz1',
            { 'type' => 'xfs', 'label' => 'foooooooooooBAAAARRRRRR' },
          )
        end

        it 'handles hybrid_xfs' do
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{-d rtinherit=1 -r rtdev=/dev/sdc1.* -L "/mnt/1" /dev/sdb1$},
            { :timeout => 600 },
          ).and_return(mock_so)
          node.default['fb_storage'] = {}
          sh = TestHandler.new('/dev/md0', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          sh.format_partition(
            '/dev/sdzz1',
            {
              'type' => 'xfs',
              'label' => '/mnt/1',
              'raid_level' => 'hybrid_xfs',
              'members' => ['/dev/sdc1'],
              'journal' => '/dev/sdb1',
            },
          )
        end

        it 'disables/enables md syncing before/after mkfs on swraid' do
          limit_file = '/proc/sys/dev/raid/speed_limit_max'
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f.*/dev/md0},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(File).to receive(:exist?).with(limit_file).
            and_return(true)
          expect(File).to receive(:read).with(limit_file).
            and_return('oogabooga')
          expect(File).to receive(:write).with(limit_file, "0\n").and_return(2)
          expect(File).to receive(:write).with(limit_file, 'oogabooga').
            and_return(9)

          node.default['fb_storage'] = {
            '_handlers' => [
              FB::Storage::Handler::MdHandler,
            ],
          }
          node.automatic['block_device'] = {}
          sh = FB::Storage::Handler.get_handler('/dev/md0', node)
          expect(sh).to receive(:umount_by_partition).and_return(nil)
          sh.format_partition(
            '/dev/md0',
            {
              'type' => 'xfs',
              'label' => '/mnt/1',
              'raid_level' => 1,
              'members' => ['/dev/sdb1', '/dev/sdc1'],
            },
          )
        end

        it 'does not touch syncing on non-MD devices' do
          limit_file = '/proc/sys/dev/raid/speed_limit_max'
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f.*/dev/sdzz1},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(File).not_to receive(:exist?).with(limit_file)
          expect(File).not_to receive(:read).with(limit_file)
          expect(File).not_to receive(:write).with(limit_file, "0\n")

          node.default['fb_storage'] = {}
          sh = TestHandler.new('/dev/sdzz1', node)
          expect(sh).to receive(:umount_by_partition).and_return(nil)
          sh.format_partition(
            '/dev/sdzz1',
            {
              'type' => 'xfs',
              'label' => '/mnt/1',
            },
          )
        end

        it 'does not touch syncing on fake-MD devices' do
          limit_file = '/proc/sys/dev/raid/speed_limit_max'
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f.*/dev/sdb1},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(File).not_to receive(:exist?).with(limit_file)
          expect(File).not_to receive(:read).with(limit_file)
          expect(File).not_to receive(:write).with(limit_file, "0\n")

          node.default['fb_storage'] = {}
          sh = FB::Storage::Handler.get_handler('/dev/md0', node)
          expect(sh).to receive(:umount_by_partition).and_return(nil)
          sh.format_partition(
            '/dev/md0',
            {
              'raid_level' => 'hybrid_xfs',
              'type' => 'xfs',
              'label' => '/mnt/1',
              'members' => ['/dev/sdc1'],
              'journal' => '/dev/sdb1',
            },
          )
        end

        it 'accepts format_options as string' do
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f blah -L \"foo\" /dev/sdzz1},
            { :timeout => 600 },
          ).and_return(mock_so)
          node.default['fb_storage'] = { 'format_options' => 'blah' }
          sh = TestHandler.new('/dev/sdzz', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          sh.format_partition(
            '/dev/sdzz1', { 'type' => 'xfs', 'label' => 'foo' }
          )
        end
      end

      context 'with more than one mkfs' do
        it 'accepts format_options as hash' do
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs.btrfs -f blah -L \"foo\" /dev/sdzz1},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t ext3 -F blah3 -L \"foo3\" /dev/sdzz2},
            { :timeout => 600 },
          ).and_return(mock_so)
          node.default['fb_storage'] = {
            'format_options' => { 'btrfs' => 'blah', 'ext3' => 'blah3' },
          }
          sh = TestHandler.new('/dev/sdzz', node)
          expect(mock_so).to receive(:error!).twice
          expect(sh).to receive(:umount_by_partition).twice
          expect(sh).to receive(:remove_device_from_any_arrays).twice
          sh.format_partition(
            '/dev/sdzz1', { 'type' => 'btrfs', 'label' => 'foo' }
          )
          sh.format_partition(
            '/dev/sdzz2', { 'type' => 'ext3', 'label' => 'foo3' }
          )
        end
      end

      context 'with unsuccessful mkfs' do
        it 'enables md syncing after mkfs even if Mixlib::ShellOut fails' do
          limit_file = '/proc/sys/dev/raid/speed_limit_max'
          expect(mock_so).to receive(:run_command).and_raise(StandardError)
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f.*/dev/md0},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(File).to receive(:exist?).with(limit_file).
            and_return(true)
          expect(File).to receive(:read).with(limit_file).
            and_return('oogabooga')
          expect(File).to receive(:write).with(limit_file, "0\n").and_return(2)
          expect(File).to receive(:write).with(limit_file, 'oogabooga').
            and_return(9)

          node.default['fb_storage'] = {}
          sh = FB::Storage::Handler.get_handler('/dev/md0', node)
          expect(sh).to receive(:umount_by_partition).and_return(nil)
          expect do
            sh.format_partition(
              '/dev/md0',
              {
                'type' => 'xfs',
                'label' => '/mnt/1',
                'raid_level' => 1,
                'members' => ['/dev/sdb1', '/dev/sdc1'],
              },
            )
          end.to raise_error(StandardError)
        end

        it 'enables md syncing after mkfs even if mkfs fails' do
          limit_file = '/proc/sys/dev/raid/speed_limit_max'
          expect(mock_so).to receive(:error!).and_raise(RuntimeError)
          expect(Mixlib::ShellOut).to receive(:new).with(
            %r{mkfs -t xfs -f.*/dev/md0},
            { :timeout => 600 },
          ).and_return(mock_so)
          expect(File).to receive(:exist?).with(limit_file).
            and_return(true)
          expect(File).to receive(:read).with(limit_file).
            and_return('oogabooga')
          expect(File).to receive(:write).with(limit_file, "0\n").and_return(2)
          expect(File).to receive(:write).with(limit_file, 'oogabooga').
            and_return(9)

          node.default['fb_storage'] = {}
          sh = FB::Storage::Handler.get_handler('/dev/md0', node)
          expect(sh).to receive(:umount_by_partition).and_return(nil)
          expect do
            sh.format_partition(
              '/dev/md0',
              {
                'type' => 'xfs',
                'label' => '/mnt/1',
                'raid_level' => 1,
                'members' => ['/dev/sdb1', '/dev/sdc1'],
              },
            )
          end.to raise_error(RuntimeError)
        end

        it 'throws unknown format_options' do
          node.default['fb_storage'] = {
            'format_options' => proc { |t| "blah_#{t}" },
          }
          sh = TestHandler.new('/dev/sdzz', node)
          expect(sh).to receive(:umount_by_partition)
          expect(sh).to receive(:remove_device_from_any_arrays)
          expect do
            sh.format_partition(
              '/dev/sdzz1', { 'type' => 'ext3', 'label' => 'foo' }
            )
          end.to raise_error(RuntimeError)
        end
      end
    end
  end

  context 'Array Helpers' do
    context '#array_device_is_in' do
      it 'find arrays device is a member of' do
        node.automatic['mdadm']['md0']['members'] = %w{foo bar sdzz2}
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh.array_device_is_in('/dev/sdzz2')).to eq('/dev/md0')
      end

      it 'find arrays device is a journal of' do
        node.automatic['mdadm']['md1']['members'] = %w{foo bar baz}
        node.automatic['mdadm']['md1']['journal'] = 'sdzz2'
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh.array_device_is_in('/dev/sdzz2')).to eq('/dev/md1')
      end

      it 'find arrays device is a spare of' do
        node.automatic['mdadm']['md1']['members'] = %w{foo bar baz}
        node.automatic['mdadm']['md1']['journal'] = 'sdzz2'
        node.automatic['mdadm']['md2']['members'] = %w{some drives here}
        node.automatic['mdadm']['md2']['spares'] = %w{sdzz3 sdq5}
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh.array_device_is_in('/dev/sdzz3')).to eq('/dev/md2')
      end
    end

    context '#remove_device_from_any_arrays' do
      it 'bails returns if an array no longer exists' do
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:array_device_is_in).and_return('/dev/md6')
        expect(File).to receive(:exist?).with('/dev/md6').and_return(false)
        expect(Mixlib::ShellOut).not_to receive(:new).with(/mdadm/)
        sh.remove_device_from_any_arrays('/dev/sdzz2')
      end

      it 'sets the device as faulty and removes it' do
        expect(mock_so).to receive(:error!)
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:array_device_is_in).and_return('/dev/md6')
        expect(File).to receive(:exist?).with('/dev/md6').and_return(true)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --fail /dev/sdzz2',
        ).and_return(mock_so)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --remove /dev/sdzz2',
        ).and_return(mock_so)
        expect(sh).to receive(:_sleep)
        sh.remove_device_from_any_arrays('/dev/sdzz2')
      end

      it 'tries the removal several times' do
        failed_mock = double(
          'failed_mock',
          {
            :stdout => 'Device or resource busy',
            :error? => true,
          },
        )
        expect(failed_mock).to receive(:run_command).exactly(6).times.
          and_return(failed_mock)
        expect(mock_so).to receive(:error!)
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:array_device_is_in).and_return('/dev/md6')
        expect(File).to receive(:exist?).with('/dev/md6').and_return(true)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --fail /dev/sdzz2',
        ).and_return(mock_so)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --remove /dev/sdzz2',
        ).exactly(6).times.and_return(failed_mock)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --remove /dev/sdzz2',
        ).and_return(mock_so)
        expect(sh).to receive(:_sleep).exactly(7).times

        sh.remove_device_from_any_arrays('/dev/sdzz2')
      end

      it 'stops the array and nukes the superblock if allowed' do
        node.default['fb_storage'][
          'stop_and_zero_mdadm_for_format'] = true
        failed_mock = double(
          'failed_mock',
          {
            :stderr => 'Device or resource busy',
            :error? => true,
          },
        )
        expect(failed_mock).to receive(:run_command).and_return(failed_mock)
        expect(mock_so).to receive(:error!)
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:array_device_is_in).and_return('/dev/md6')
        expect(File).to receive(:exist?).with('/dev/md6').exactly(
          2,
        ).times.and_return(true)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --fail /dev/sdzz2',
        ).and_return(failed_mock)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm -S /dev/md6',
        ).and_return(mock_so)

        expect(sh).to receive(:nuke_raid_header).with('/dev/sdzz2')

        sh.remove_device_from_any_arrays('/dev/sdzz2')
      end

      it 'does not stop the array and nuke the superblock if not allowed' do
        node.default['fb_storage'][
          'stop_and_zero_mdadm_for_format'] = false
        failed_mock = double(
          'failed_mock',
          {
            :stderr => 'Device or resource busy',
            :error? => true,
          },
        )
        expect(failed_mock).to receive(:run_command).and_return(failed_mock)
        expect(failed_mock).to receive(:error!).and_raise(
          Mixlib::ShellOut::ShellCommandFailed,
        )
        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh).to receive(:array_device_is_in).and_return('/dev/md6')
        expect(File).to receive(:exist?).with('/dev/md6').and_return(true)
        expect(Mixlib::ShellOut).to receive(:new).with(
          '/sbin/mdadm /dev/md6 --fail /dev/sdzz2',
        ).and_return(failed_mock)
        expect(Mixlib::ShellOut).not_to receive(:new).with(
          '/sbin/mdadm --stop /dev/md6',
        )
        expect(sh).not_to receive(:nuke_raid_header).with('/dev/sdzz2')

        expect do
          sh.remove_device_from_any_arrays('/dev/sdzz2')
        end.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      end
    end

    context '#remove_all_partitions_from_all_arrays' do
      it 'removes both the device and any partitions from all arrays' do
        sh = TestHandler.new('/dev/sdzz', node)
        partitions = ['/dev/sdzz2', '/dev/sdzz5']
        expect(sh).to receive(:existing_partitions).and_return(partitions)
        expect(sh).to receive(:remove_from_arrays).with(
          partitions + ['/dev/sdzz'],
        ).and_return([])
        sh.remove_all_partitions_from_all_arrays
      end

      it 'nukes headers for any devices it removes from arrays' do
        sh = TestHandler.new('/dev/sdzz', node)
        partitions = ['/dev/sdzz2', '/dev/sdzz5']
        expect(sh).to receive(:existing_partitions).and_return(partitions)
        expect(sh).to receive(:remove_from_arrays).with(
          partitions + ['/dev/sdzz'],
        ).and_return(['foo'])
        expect(sh).to receive(:nuke_raid_header).with('foo')
        sh.remove_all_partitions_from_all_arrays
      end
    end
  end

  context 'other helpers' do
    context '#existing_partitions' do
      it 'finds all partitions' do
        # Similarly, all tests happen on sdzX to decrease any chance of
        # actually being related to real disks
        node.automatic[attr_name]['by_device'] = {
          '/dev/sdzz' => {},
          '/dev/sdzz1' => {},
          '/dev/sdzz2' => {},
          '/dev/sdzz3' => {},
          '/dev/sdzz4' => {},
          '/dev/sdzz5' => {},
          '/dev/sdzz6' => {},
        }

        sh = TestHandler.new('/dev/sdzz', node)
        expect(sh.existing_partitions).to eq(
          6.times.map { |x| "/dev/sdzz#{x + 1}" },
        )
      end

      it 'finds all partitions on weirdly named devices' do
        # Similarly, all tests happen on sdzX to decrease any chance of
        # actually being related to real disks
        node.automatic[attr_name]['by_device'] = {
          '/dev/nvme999n0' => {},
          '/dev/nvme999n0p1' => {},
          '/dev/nvme999n0p2' => {},
        }

        sh = TestHandler.new('/dev/nvme999n0', node)
        expect(sh.existing_partitions).to eq(
          %w{/dev/nvme999n0p1 /dev/nvme999n0p2},
        )
      end
    end
  end
end
