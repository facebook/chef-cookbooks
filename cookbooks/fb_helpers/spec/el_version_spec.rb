# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2024-present, Meta Platforms, Inc.
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

require './spec/spec_helper'
require_relative '../libraries/fb_helpers'
require_relative '../libraries/node_methods'

describe 'Chef::Node' do
  let(:node) { Chef::Node.new }

  context 'Chef::Node.el_min_version?' do
    before(:each) do
      node.default['platform_version'] = '8.2'
      node.default['platform_family'] = 'rhel'
    end

    it 'should report correct version' do
      expect(node._self_version).to eq(FB::Version.new('8.2'))
    end

    it 'should be min 8' do
      expect(node.el_min_version?(8)).to eq(true)
    end

    it 'should not be min 9' do
      expect(node.el_min_version?(9)).to eq(false)
    end
  end

  context 'Chef::Node.el_max_version?' do
    before(:each) do
      node.default['platform_version'] = '9.2'
      node.default['platform_family'] = 'rhel'
    end

    it 'should report correct version' do
      expect(node._self_version).to eq(FB::Version.new('9.2'))
    end

    it 'should be max 9' do
      expect(node.el_max_version?(9)).to eq(true)
    end

    it 'should not be max 8' do
      expect(node.el_max_version?(8)).to eq(false)
    end
  end
end
