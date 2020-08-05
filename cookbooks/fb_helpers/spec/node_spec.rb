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
      Chef::Log.should_not_receive(:warn)
      node.fs_size_gb('/').should eq(914.6791610717773)
    end

    it 'should warn and return true' do
      Chef::Log.should_receive(:warn)
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
      Chef::Log.should_not_receive(:warn)
      node.fs_size_kb('/').should eq(959110616.0)
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
      Chef::Log.should_not_receive(:warn)
      node.fs_value('/', 'size').should eq(959110616.0)
      node.fs_value('/', 'available').should eq(810110218.0)
      node.fs_value('/', 'used').should eq(149000398.0)
      node.fs_value('/', 'percent').should eq(15.0)
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
      node.in_flexible_shard?(66, 100).should eq(true)
      node.in_flexible_shard?(466, 1000).should eq(true)
      node.in_flexible_shard?(116, 255).should eq(true)
      node.in_flexible_shard?(2, 12).should eq(true)
    end
    it 'should return false if we are not in flexible_shard' do
      node.in_flexible_shard?(65, 100).should eq(false)
      node.in_flexible_shard?(465, 1000).should eq(false)
      node.in_flexible_shard?(115, 255).should eq(false)
      node.in_flexible_shard?(1, 12).should eq(false)
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
        node.in_timeshard?(
          (Time.now - (our_shard - 1)).to_s,
          duration,
        ).should eq(false)
      end

      it "should return true the second of our shard - #{duration}" do
        our_shard = node.get_flexible_shard(seconds)
        node.in_timeshard?(
          (Time.now - our_shard).to_s,
          duration,
        ).should eq(true)
      end

      it "should return true much later than our shard - #{duration}" do
        node.in_timeshard?(
          (Time.now - (seconds - 1)).to_s,
          duration,
        ).should eq(true)
      end

      it "should return false much earlier than our shard - #{duration}" do
        node.in_timeshard?(
          (Time.now - 1).to_s,
          duration,
        ).should eq(false)
      end

      it "should fail if start_time is formatted wrong - #{duration}" do
        expect do
          node.in_timeshard?(
            '2018-09-01i 09:00:00',
            duration,
          )
        end.to raise_error(RuntimeError)
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
      node.in_timeshard?(
        start_time,
        '40d',
      ).should eq(true)
    end
  end

  context 'Chef::Node.systemd?' do
    it 'should check the running system for running systemd' do
      ::File.stub(:directory?).with(anything).and_call_original
      ::File.stub(:directory?).with('/run/systemd/system').
        and_return true
      node.systemd?.should eq(true)
    end
    it 'should check the running system for systemd not running' do
      ::File.stub(:directory?).with(anything).and_call_original
      ::File.stub(:directory?).with('/run/systemd/system').
        and_return false
      node.systemd?.should eq(false)
    end
  end
end
