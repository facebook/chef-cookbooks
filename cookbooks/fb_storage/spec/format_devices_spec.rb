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
require_relative '../libraries/storage'
require_relative '../libraries/format_devices_provider'

describe FB::Storage::FormatDevicesProvider do
  include FB::Storage::FormatDevicesProvider

  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end

  context '#filter_work' do
    let(:data) do
      {
        :missing_partitions => ['a'],
        :mismatched_partitions => ['b'],
        :missing_filesystems => ['c'],
        :mismatched_filesystems => ['d'],
        :missing_arrays => ['e'],
        :mismatched_arrays => ['f'],
      }
    end
    let(:arrays) do
      {
        'e' => { 'members' => ['c'] },
        'f' => { 'members' => ['d'] },
      }
    end

    it 'handles :all' do
      expect(filter_work(data, :all, nil)).to eq(
        {
          :devices => ['a', 'b'],
          :partitions => ['c', 'd'],
          :arrays => ['e', 'f'],
        },
      )
    end

    it 'handles :missing' do
      fake_storage = double('storage')
      allow(fake_storage).to receive(:arrays).and_return(arrays)
      node.automatic[attr_name]['by_device'] = {
        'c' => {},
        'd' => {},
      }
      expect(filter_work(data, :missing, fake_storage)).to eq(
        {
          :devices => ['a'],
          :partitions => ['c'],
          :arrays => ['e'],
        },
      )
    end

    it 'handles :missing - and strips arrays with mounted members' do
      fake_storage = double('storage')
      allow(fake_storage).to receive(:arrays).and_return(arrays)
      node.automatic[attr_name]['by_device'] = {
        'c' => { 'mount_point' => '/mp' },
        'd' => {},
      }
      expect(filter_work(data, :missing, fake_storage)).to eq(
        {
          :devices => ['a'],
          :partitions => ['c'],
          :arrays => [],
        },
      )
    end

    it 'handles :filesystems' do
      expect(filter_work(data, :filesystems, nil)).to eq(
        {
          :devices => [],
          :partitions => ['c', 'd'],
          :arrays => [],
        },
      )
    end
  end

  context '#merge_work' do
    it 'handles stuff on the left and right' do
      expect(
        merge_work(
          {
            :devices => ['a'],
            :partitions => ['b'],
            :arrays => ['c'],
          },
          {
            :devices => ['d'],
            :partitions => ['e'],
            :arrays => ['f'],
          },
        ),
      ).to eq(
        {
          :devices => ['a', 'd'],
          :partitions => ['b', 'e'],
          :arrays => ['c', 'f'],
        },
      )
    end

    it 'strips duplicates' do
      expect(
        merge_work(
          {
            :devices => ['a'],
            :partitions => ['b'],
            :arrays => ['c'],
          },
          {
            :devices => ['a'],
            :partitions => ['b'],
            :arrays => ['f'],
          },
        ),
      ).to eq(
        {
          :devices => ['a'],
          :partitions => ['b'],
          :arrays => ['c', 'f'],
        },
      )
    end

    it 'handles empty arrays on either side' do
      expect(
        merge_work(
          {
            :devices => [],
            :partitions => ['b'],
            :arrays => ['c'],
          },
          {
            :devices => ['a'],
            :partitions => ['b'],
            :arrays => [],
          },
        ),
      ).to eq(
        {
          :devices => ['a'],
          :partitions => ['b'],
          :arrays => ['c'],
        },
      )
    end
  end

  context 'work to do' do
    let(:fake_storage) { double('fake_storage') }
    let(:data) do
      {
        :missing_partitions => ['a'],
        :mismatched_partitions => ['b'],
        :missing_filesystems => ['c'],
        :mismatched_filesystems => ['d'],
        :missing_arrays => ['e'],
        :mismatched_arrays => ['f'],
        :incomplete_arrays => {},
      }
    end
    let(:default_perms) do
      {
        'firstboot_converge' => true,
        'firstboot_eraseall' => false,
        'hotswap' => true,
        'missing_filesystem_or_partition' => false,
        'mismatched_filesystem_or_partition' => false,
        'mismatched_filesystem_only' => false,
      }
    end
    let(:all_storage) do
      {
        :devices => ['g'],
        :partitions => ['h'],
        :arrays => ['i'],
      }
    end
    let(:arrays) do
      {
        'e' => { 'members' => ['j', 'k'] },
        'f' => { 'members' => ['l', 'm'] },
      }
    end
    let(:fake_storage) { double('storage') }

    context '#get_primary_work' do
      context 'default data' do
        before(:each) do
          allow(fake_storage).to receive(:out_of_spec).and_return(data)
          allow(fake_storage).to receive(:all_storage).and_return(all_storage)
          allow(fake_storage).to receive(:arrays).and_return(arrays)
          allow(File).to receive(:exist?).with(
            FB::Storage::ERASE_ALL_FILE,
          ).and_return(false)
          allow(File).to receive(:exist?).with(
            FB::Storage::CONVERGE_ALL_FILE,
          ).and_return(false)
        end

        it 'handles erase_all override file when override method is defined ' +
           'and succeeds' do
          allow(File).to receive(:exist?).with(
            FB::Storage::ERASE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['_clowntown_override_file_method'] =
            proc { true }
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['g'],
              :partitions => ['h'],
              :arrays => ['i'],
            },
          )
        end

        it 'ignores erase_all override file when override method is defined ' +
           'and fails' do
          allow(File).to receive(:exist?).with(
            FB::Storage::ERASE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['_clowntown_override_file_method'] =
            proc { false }
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => [],
              :partitions => [],
              :arrays => [],
            },
          )
        end

        it 'ignores erase_all override file when override method is not ' +
           'defined' do
          allow(File).to receive(:exist?).with(
            FB::Storage::ERASE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => [],
              :partitions => [],
              :arrays => [],
            },
          )
        end

        it 'handles converge_all override file when override method is ' +
           'defined and succeeds' do
          allow(File).to receive(:exist?).with(
            FB::Storage::CONVERGE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['_clowntown_override_file_method'] =
            proc { true }
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['a', 'b'],
              :partitions => ['c', 'd'],
              :arrays => ['e', 'f'],
            },
          )
        end

        it 'ignores converge_all override file when override method is ' +
           'defined and fails' do
          allow(File).to receive(:exist?).with(
            FB::Storage::CONVERGE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['_clowntown_override_file_method'] =
            proc { false }
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => [],
              :partitions => [],
              :arrays => [],
            },
          )
        end

        it 'ignores converge_all override file when override method is not ' +
           'defined' do
          allow(File).to receive(:exist?).with(
            FB::Storage::CONVERGE_ALL_FILE,
          ).and_return(true)
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => [],
              :partitions => [],
              :arrays => [],
            },
          )
        end

        it 'filters all filesystems with default perms, not firstboot, ' +
            'no hotswap' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => [], :partitions => [], :arrays => [] },
          )
        end

        it 'filters all filesystems except hotswap, with default perms' do
          allow(fake_storage).to receive(:hotswap_disks).and_return(['a'])
          allow(fake_storage).to receive(:config).and_return(
            { 'a' => { 'partitions' => [{}] } },
          )
          node.default['fb_storage']['format'] = default_perms
          allow(node).to receive(:firstboot_tier?).and_return(false)
          # one partition defined in `config` above, so the partition will
          # be a1
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => ['a'], :partitions => ['a1'], :arrays => [] },
          )
        end

        it 'skips hotswap disks marked skip' do
          allow(fake_storage).to receive(:hotswap_disks).and_return(['a', 'b'])
          allow(fake_storage).to receive(:config).and_return(
            { 'a' => { 'partitions' => [{}] }, 'b' => { '_skip' => true } },
          )
          node.default['fb_storage']['format'] = default_perms
          allow(node).to receive(:firstboot_tier?).and_return(false)
          # one partition defined in `config` above, so the partition will
          # be a1
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => ['a'], :partitions => ['a1'], :arrays => [] },
          )
        end

        it 'allows all convergance on firstboot, when allowed' do
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'firstboot_converge'] = true
          allow(node).to receive(:firstboot_tier?).and_return(true)
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['a', 'b'],
              :partitions => ['c', 'd'],
              :arrays => ['e', 'f'],
            },
          )
        end

        it 'converges missing partitions, when allowed' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'missing_filesystem_or_partition'] = true
          node.automatic[attr_name]['by_device'] = {
            'j' => {},
            'k' => {},
          }
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => ['a'], :partitions => ['c'], :arrays => ['e'] },
          )
        end

        it 'does not converge missing arrays, when allowed to, but would ' +
            'effect mounted filesystems' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'missing_filesystem_or_partition'] = true
          allow(node).to receive(:firstboot_tier?).and_return(false)
          node.automatic[attr_name]['by_device'] = {
            'j' => { 'mount_point' => '/data/fa' },
            'k' => {},
          }
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['a'],
              :partitions => ['c'],
              :arrays => [],
            },
          )
        end

        it 'converges mismatched partition tables, when allowed' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'mismatched_filesystem_or_partition'] = true
          allow(node).to receive(:firstboot_tier?).and_return(false)
          # mismatched partitions implies missing partitions, so both
          # devices
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['a', 'b'],
              :partitions => ['c', 'd'],
              :arrays => ['e', 'f'],
            },
          )
        end

        it 'converges mismatched filesystems only, when allowed' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'mismatched_filesystem_only'] = true
          allow(node).to receive(:firstboot_tier?).and_return(false)
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => [], :partitions => ['c', 'd'], :arrays => [] },
          )
        end

        it 'converges mismatched arrays even if mounted, when allowed' do
          allow(fake_storage).to receive(:hotswap_disks).and_return([])
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'mismatched_filesystem_or_partition'] = true
          allow(node).to receive(:firstboot_tier?).and_return(false)
          node.automatic[attr_name]['by_device'] = {
            'j' => { 'mount_point' => '/data/fa' },
            'k' => {},
          }
          expect(get_primary_work(fake_storage)).to eq(
            {
              :devices => ['a', 'b'],
              :partitions => ['c', 'd'],
              :arrays => ['e', 'f'],
            },
          )
        end
      end

      context 'empty data' do
        it 'nukes all disks on firstboot when allowed' do
          empty_data = {
            :missing_partitions => [],
            :mismatched_partitions => [],
            :missing_filesystems => [],
            :mismatched_filesystems => [],
          }
          allow(fake_storage).to receive(:out_of_spec).and_return(empty_data)
          allow(fake_storage).to receive(:all_storage).and_return(all_storage)
          node.default['fb_storage']['format'] = default_perms
          node.default['fb_storage']['format'][
            'firstboot_eraseall'] = true
          expect(node).to receive(:firstboot_tier?).and_return(true)
          expect(get_primary_work(fake_storage)).to eq(
            { :devices => ['g'], :partitions => ['h'], :arrays => ['i'] },
          )
        end
      end
    end

    context '#fill_in_dynamic_work' do
      let(:fake_storage) { double('fake storage') }

      it 'does not fill in array members without permission' do
        data = {
          :incomplete_arrays => {
            '/dev/md0' => ['/dev/sdzz1', '/dev/sdzy1'],
          },
          :missing_arrays => [],
          :mismatched_arrays => [],
          :extra_arrays => [],
        }
        to_do = {
          :devices => [],
          :partitions => [],
          :arrays => [],
        }
        node.automatic[attr_name]['by_device'] = {}
        node.default['fb_storage']['format'] = default_perms
        allow(fake_storage).to receive(:out_of_spec).and_return(data)
        allow(node).to receive(:firstboot_tier?).and_return(false)
        expect(fill_in_dynamic_work(to_do, fake_storage)[:fill_arrays]).
          to eq({})
      end

      it 'fills in array members with permission' do
        data = {
          :incomplete_arrays => {
            '/dev/md0' => ['/dev/sdzz1', '/dev/sdzy1'],
          },
          :missing_arrays => [],
          :mismatched_arrays => [],
          :extra_arrays => [],
        }
        to_do = {
          :devices => [],
          :partitions => [],
          :arrays => [],
        }
        node.automatic[attr_name]['by_device'] = {}
        node.default['fb_storage']['format'][
          'missing_filesystems_or_partitions'] = true
        allow(fake_storage).to receive(:out_of_spec).and_return(data)
        allow(node).to receive(:firstboot_tier?).and_return(false)
        expect(fill_in_dynamic_work(to_do, fake_storage)[:fill_arrays]).to eq(
          { '/dev/md0' => ['/dev/sdzz1', '/dev/sdzy1'] },
        )
      end

      # we're going to pull a disk from an array, make sure we add it back
      it 'fills in disks we will be messing with' do
        data = {
          :incomplete_arrays => {},
          :missing_arrays => [],
          :mismatched_arrays => [],
          :extra_arrays => [],
        }
        to_do = {
          :devices => [],
          :partitions => ['/dev/sdzy1', '/dev/sdzz1'],
          :arrays => [],
        }
        arrays = {
          '/dev/md0' => { 'members' => ['a', 'b', 'c', '/dev/sdzy1'] },
        }
        node.default['fb_storage']['format'] = default_perms
        allow(fake_storage).to receive(:out_of_spec).and_return(data)
        allow(fake_storage).to receive(:arrays).and_return(arrays)
        allow(node).to receive(:firstboot_tier?).and_return(false)
        expect(fill_in_dynamic_work(to_do, fake_storage)[:fill_arrays]).to eq(
          { '/dev/md0' => ['/dev/sdzy1'] },
        )
      end

      it 'stops arrays we will fully empty and do not want' do
        data = {
          :incomplete_arrays => {},
          :missing_arrays => [],
          :mismatched_arrays => [],
          :extra_arrays => ['/dev/md1'],
        }
        to_do = {
          :devices => [],
          :partitions => ['/dev/sdzy1', '/dev/sdzz1'],
          :arrays => [],
        }
        arrays = {
          '/dev/md0' => { 'members' => ['a', 'b', 'c', '/dev/sdzy1'] },
        }
        node.automatic['mdadm']['md1']['members'] = ['sdzy1', 'sdzz1']
        node.default['fb_storage']['format'] = default_perms
        allow(fake_storage).to receive(:out_of_spec).and_return(data)
        allow(fake_storage).to receive(:arrays).and_return(arrays)
        allow(node).to receive(:firstboot_tier?).and_return(false)
        expect(fill_in_dynamic_work(to_do, fake_storage)[:stop_arrays]).to eq(
          ['/dev/md1'],
        )
      end

      it 'does not stop arrays we are not touching every device of' do
        data = {
          :incomplete_arrays => {},
          :missing_arrays => [],
          :mismatched_arrays => [],
          :extra_arrays => ['/dev/md1'],
        }
        to_do = {
          :devices => [],
          :partitions => ['/dev/sdzy1', '/dev/sdzz1'],
          :arrays => [],
        }
        arrays = {
          '/dev/md0' => { 'members' => ['a', 'b', 'c', '/dev/sdzy1'] },
        }
        node.automatic['mdadm']['md1']['members'] = ['sdzy1', 'sdzz1', 'lol']
        node.default['fb_storage']['format'] = default_perms
        allow(fake_storage).to receive(:out_of_spec).and_return(data)
        allow(fake_storage).to receive(:arrays).and_return(arrays)
        allow(node).to receive(:firstboot_tier?).and_return(false)
        expect(fill_in_dynamic_work(to_do, fake_storage)[:stop_arrays]).to eq(
          [],
        )
      end
    end
  end
end
