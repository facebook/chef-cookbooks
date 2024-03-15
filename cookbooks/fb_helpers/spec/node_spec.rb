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
require_relative '../libraries/fb_helpers'
require_relative '../libraries/node_methods'

describe 'Chef::Node' do
  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end

  context 'Chef::Node.fs_size_gb' do
    before(:each) do
      node.default[attr_name]['by_mountpoint']['/'] = {
        'kb_size' => '959110616',
        'devices' => ['/dev/sda3'],
      }
    end

    it 'should return size in GB' do
      expect(Chef::Log).not_to receive(:warn)
      expect(node.fs_size_gb('/')).to eq(914.6791610717773)
    end

    it 'should warn and return true' do
      expect(Chef::Log).to receive(:warn)
      node.fs_size_gb('/fake')
    end
  end

  context 'Chef::Node.fs_size_kb' do
    before do
      node.default[attr_name]['by_mountpoint']['/'] = {
        'kb_size' => '959110616',
        'devices' => ['/dev/sda3'],
      }
    end

    it 'should return size in KB' do
      expect(Chef::Log).not_to receive(:warn)
      expect(node.fs_size_kb('/')).to eq(959110616.0)
    end
  end

  context 'Chef::Node.fs_value' do
    before do
      node.default[attr_name]['by_mountpoint']['/'] = {
        'kb_size' => '959110616',
        'kb_available' => '810110218',
        'kb_used' => '149000398',
        'percent_used' => '15%',
        'devices' => ['/dev/sda3'],
      }
    end

    it 'should return various values as requested' do
      expect(Chef::Log).not_to receive(:warn)
      expect(node.fs_value('/', 'size')).to eq(959110616.0)
      expect(node.fs_value('/', 'available')).to eq(810110218.0)
      expect(node.fs_value('/', 'used')).to eq(149000398.0)
      expect(node.fs_value('/', 'percent')).to eq(15.0)
    end

    it 'should throw an error on invalid args' do
      expect { node.fs_value('/', 'wasdfa') }.to raise_error(RuntimeError)
    end
  end

  context 'Chef::Node.in_flexible_shard?' do
    before do
      # Taken from dev1020.prn2.facebook.com
      # This will be shard 66 in 100
      #   or 466 in 1000
      #   or 116 in 255
      #   or 2 in 12
      node.default['shard_seed'] = 244690466
      node.default['fqdn'] = 'dev1020.prn2.facebook.com'
    end
    it 'should return true if we are in flexible_shard' do
      expect(node.in_flexible_shard?(66, 100)).to eq(true)
      expect(node.in_flexible_shard?(99, 100)).to eq(true)
      expect(node.in_flexible_shard?(466, 1000)).to eq(true)
      expect(node.in_flexible_shard?(116, 255)).to eq(true)
      expect(node.in_flexible_shard?(2, 12)).to eq(true)
    end
    it 'should return false if we are not in flexible_shard' do
      expect(node.in_flexible_shard?(0, 100)).to eq(false)
      expect(node.in_flexible_shard?(65, 100)).to eq(false)
      expect(node.in_flexible_shard?(465, 1000)).to eq(false)
      expect(node.in_flexible_shard?(115, 255)).to eq(false)
      expect(node.in_flexible_shard?(1, 12)).to eq(false)
    end
    it 'should have consistent overflow behaviour' do
      expect(node.in_flexible_shard?(100, 100)).to eq(true)
      expect(node.in_flexible_shard?(199, 100)).to eq(true)
    end
    it 'should have consistent underflow behaviour' do
      expect(node.in_flexible_shard?(-1, 100)).to eq(false)
      expect(node.in_flexible_shard?(-99, 100)).to eq(false)
    end
  end

  context 'Chef::Node.get_flexible_shard' do
    before do
      # Taken from dev1020.prn2.facebook.com
      # This will be shard 66 in 100
      node.default['shard_seed'] = 244690466
      node.default['fqdn'] = 'dev1020.prn2.facebook.com'
    end
    it 'should return correct shard on multiple calls' do
      expect(node.get_flexible_shard(100)).to eq(66)
      # Should remain 66 on second calling
      expect(node.get_flexible_shard(100)).to eq(66)
    end
  end

  context 'Chef::Node.in_shard?' do
    before do
      # Taken from dev1020.prn2.facebook.com
      # This will be shard 66 in 100
      node.default['shard_seed'] = 244690466
      node.default['fqdn'] = 'dev1020.prn2.facebook.com'
    end
    it 'should return true if we are in shard' do
      expect(node.in_shard?(66)).to eq(true)
      # Should remain true on second calling
      expect(node.in_shard?(66)).to eq(true)

      expect(node.in_shard?(67)).to eq(true)
    end
    it 'should return false if we are not in shard' do
      expect(node.in_shard?(65)).to eq(false)
      # Should remain false on second calling
      expect(node.in_shard?(65)).to eq(false)
    end
    it 'should retain legacy overflow behaviour' do
      # avoid using literals so linters don't fire
      [100, 199].each do |v|
        expect(node.in_shard?(v)).to eq(true)
      end
    end
    it 'should retain legacy underflow behaviour' do
      # avoid using literals so linters don't fire
      [-1, -99].each do |v|
        expect(node.in_shard?(v)).to eq(false)
      end
    end
  end

  context 'Chef::Node.timeshard_parsed_values' do
    # for the purposes of this test we want a consistent shard_seed
    # this will map to 51336 seconds into a 24h (86400 second) period.
    before do
      node.default['fb']['shard_seed'] = 31328136
    end

    {
      '24h' => (24 * 60 * 60),
      '1h' => (60 * 60),
      '7d' => (7 * 24 * 60 * 60),
    }.each do |duration, seconds|
      it "should return the correct values for each duration - #{duration}" do
        our_shard = node.get_flexible_shard(seconds)

        start_time = Time.now - (our_shard - 1)

        duration_value = seconds
        time_threshold_value = our_shard + start_time.tv_sec

        expect(node.timeshard_parsed_values(
                 start_time.to_s,
                 duration,
        )).to eq({
                   'start_time' => start_time.tv_sec,
                      'duration' => duration_value,
                      'time_threshold' => time_threshold_value,
                 })
      end
    end
  end

  context 'Chef::Node.in_timeshard?' do
    # for the purposes of this test we want a consistent shard_seed
    # this will map to 51336 seconds into a 24h (86400 second) period.
    before do
      node.default['fb']['shard_seed'] = 31328136
    end

    {
      '24h' => (24 * 60 * 60),
      '1h' => (60 * 60),
      '7d' => (7 * 24 * 60 * 60),
    }.each do |duration, seconds|
      it "should return false the second before our shard - #{duration}" do
        our_shard = node.get_flexible_shard(seconds)
        expect(node.in_timeshard?(
                 (Time.now - (our_shard - 1)).to_s,
                 duration,
        )).to eq(false)
      end

      it "should return true the second of our shard - #{duration}" do
        our_shard = node.get_flexible_shard(seconds)
        expect(node.in_timeshard?(
                 (Time.now - our_shard).to_s,
                 duration,
        )).to eq(true)
      end

      it "should return true much later than our shard - #{duration}" do
        expect(node.in_timeshard?(
                 (Time.now - (seconds - 1)).to_s,
                 duration,
        )).to eq(true)
      end

      it "should return false much earlier than our shard - #{duration}" do
        expect(node.in_timeshard?(
                 (Time.now - 1).to_s,
                 duration,
        )).to eq(false)
      end

      it "should fail if start_time is an invalid time - #{duration}" do
        expect do
          node.in_timeshard?(
            '2018-14-1 9:00:00',
            duration,
          )
        end.to raise_error(RuntimeError)
      end
    end

    it 'should return true for valid times w single digits' do
      last_month = Date.today.prev_month
      start_time = Time.new(last_month.year, last_month.month, 1, 0, 0, 0)

      # Build a string that always has a single digit hour and day value.
      start_time = start_time.strftime('%Y-%m-%-d %-H:%M:%S')
      expect(node.in_timeshard?(
               start_time,
               '40d',
      )).to eq(true)
    end
  end

  context 'Chef::Node.systemd?' do
    it 'should check the running system for running systemd' do
      allow(::File).to receive(:directory?).with(anything).and_call_original
      allow(::File).to receive(:directory?).with('/run/systemd/system').
        and_return true
      expect(node.systemd?).to eq(true)
    end
    it 'should check the running system for systemd not running' do
      allow(::File).to receive(:directory?).with(anything).and_call_original
      allow(::File).to receive(:directory?).with('/run/systemd/system').
        and_return false
      expect(node.systemd?).to eq(false)
    end
  end

  context 'Chef::Node.validate_and_fail_on_dynamic_addresses' do
    it 'no addresses; no failure' do
      node.validate_and_fail_on_dynamic_addresses
    end

    before do
      node.automatic['network']['interfaces']['eth0']['addresses'][
        '2001:db8:3c4d:15::1a2f:1a2b']
    end
    it 'no address family; no failure' do
      node.validate_and_fail_on_dynamic_addresses
    end

    before do
      node.automatic['network']['interfaces']['eth0']['addresses'][
        '2001:db8:3c4d:15::1a2f:1a2b']['family'] = 'inet6'
    end
    it 'no tags; no failure' do
      node.validate_and_fail_on_dynamic_addresses
    end

    it 'no dynamic tags; no failure' do
      node.automatic['network']['interfaces']['eth0']['addresses'][
        '2001:db8:3c4d:15::1a2f:1a2b']['tags'] = ['scope', 'global']
      node.validate_and_fail_on_dynamic_addresses
    end

    it 'should fail because of a dynamic address' do
      node.automatic['network']['interfaces']['eth0']['addresses'][
        '2001:db8:3c4d:15::1a2f:1a2b']['tags'] = ['scope', 'global', 'dynamic']
      expect do
        node.validate_and_fail_on_dynamic_addresses
      end.to raise_error(RuntimeError)
    end
  end

  context 'Chef::Node.disruptable?' do
    it 'is not disruptable by default' do
      expect(node.disruptable?).to be(false)
    end

    it 'is not disruptable unless in provisioning or upon boot' do
      allow(node).to receive(:firstboot_any_phase?).and_return(false)
      ENV.stub(:[]).with('CHEF_BOOT_SERVICE').and_return ''
      expect(node.disruptable?).to be(false)
    end

    it 'is disruptable when in provisioning' do
      allow(node).to receive(:firstboot_any_phase?).and_return(true)
      ENV.stub(:[]).with('CHEF_BOOT_SERVICE').and_return ''
      expect(node.disruptable?).to be(true)
    end

    it 'is disruptable when booting' do
      allow(node).to receive(:firstboot_any_phase?).and_return(false)
      ENV.stub(:[]).with('CHEF_BOOT_SERVICE').and_return 'true'
      expect(node.disruptable?).to be(true)
    end
  end
end
