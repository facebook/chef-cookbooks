# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
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
require_relative '../libraries/default'
require_relative '../../fb_helpers/libraries/node_methods'
require_relative 'libs'

describe 'fb_swap' do
  let(:node) { Chef::Node.new }

  before(:each) do
    node.default['fb_swap']['filesystem'] = '/'
    node.default['filesystem']['by_mountpoint']['/'] = {
      'fs_type' => 'ext4',
      'devices' => ['/dev/blocka42'],
    }
  end

  context 'btrfs' do
    before do
      node.default['filesystem']['by_mountpoint']['/']['fs_type'] = 'btrfs'
    end
    it 'should return false if btrfs' do
      FB::FbSwap.swap_file_possible?(node).should eq(false)
    end
  end

  context 'rotational' do
    before do
      mock_lsblk('1')
    end
    it 'should return false if rotational' do
      FB::FbSwap.swap_file_possible?(node).should eq(false)
    end
  end

  context 'default' do
    before do
      mock_lsblk('0')
    end
    it 'should return true if not btrfs, and not rotational' do
      FB::FbSwap.swap_file_possible?(node).should eq(true)
    end
  end
end
