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
    node.default['fb_swap']['min_additional_file_size'] = 16 * 1024 * 1024
  end

  context 'btrfs' do
    before do
      node.default['filesystem']['by_mountpoint']['/']['fs_type'] = 'btrfs'
    end
    it 'should return false if btrfs' do
      expect(FB::FbSwap.swap_file_possible?(node)).to eq(false)
    end
  end

  context 'rotational' do
    before do
      mock_lsblk('1')
    end
    it 'should return false if rotational' do
      expect(FB::FbSwap.swap_file_possible?(node)).to eq(false)
    end
  end

  context 'default' do
    before do
      mock_lsblk('0')
    end
    it 'should return true if not btrfs, and not rotational' do
      expect(FB::FbSwap.swap_file_possible?(node)).to eq(true)
    end
  end

  context 'no need for add. swap file if swapoff reason is defined' do
    it 'should return -1 for additional_file_size_bytes' do
      node.default['fb_swap']['swapoff_allowed_because'] = 'Non empty reason'
      _, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(1, 1, 1, node)
      expect(additional_file_size_bytes).to eq(-1)
    end
  end

  context 'no need for add. swap file if main swap file size is enough' do
    it 'should return -1 for additional_file_size_bytes' do
      _, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(2, 2, 1, node)
      expect(additional_file_size_bytes).to eq(-1)
    end
  end

  context 'no need for add. swap file if main swap file does not exist' do
    it 'should return -1 for additional_file_size_bytes' do
      _, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(2, -1, -1, node)
      expect(additional_file_size_bytes).to eq(-1)
    end
  end

  BYTES_IN_14_1G = 16 * 1024 * 1024 * 1024 - 2048917504
  BYTES_IN_16G = 16 * 1024 * 1024 * 1024
  BYTES_IN_32G = 32 * 1024 * 1024 * 1024

  context 'need for add. swap file if main swap file size is not enough' do
    it 'should return file sizes correct' do
      file_size_bytes, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(
          BYTES_IN_32G, BYTES_IN_16G, -1, node
        )
      expect(file_size_bytes).to eq(BYTES_IN_16G)
      expect(additional_file_size_bytes).to eq(BYTES_IN_16G)
    end
  end

  context 'no need to recreate add. swap file if it has correct size' do
    it 'should return file sizes correct' do
      file_size_bytes, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(2, 1, 1, node)
      expect(file_size_bytes).to eq(1)
      expect(additional_file_size_bytes).to eq(1)
    end
  end

  context 'Unsatisfiable requested file sizes(both files exist)' do
    it 'should return current file sizes' do
      file_size_bytes, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(3, 1, 1, node)
      expect(file_size_bytes).to eq(1)
      expect(additional_file_size_bytes).to eq(1)
    end
  end
  # Side effect mitigation of the bug(https://fb.me/swapfilebug)
  context 'no need for add. swap file if size is less than min size(16GB)' do
    it 'should return -1 for additional_file_size_bytes' do
      file_size_bytes, additional_file_size_bytes =
        FB::FbSwap._validate_resize_additional_file(
          BYTES_IN_16G, BYTES_IN_14_1G, -1, node
        )
      expect(file_size_bytes).to eq(BYTES_IN_14_1G)
      expect(additional_file_size_bytes).to eq(-1)
    end
  end
end
