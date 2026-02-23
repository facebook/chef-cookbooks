# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2024-present, Meta Platforms, Inc. and affiliates
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

  context 'Any OS v 8.2' do
    before(:each) do
      node.automatic['platform_version'] = '8.2'
      node.automatic['platform_family'] = 'rhel'
    end

    it 'should report correct version' do
      expect(node._self_version).to eq(FB::Version.new('8.2'))
    end

    context 'Chef::Node.os_min_version?' do
      it 'should be min 7 and 8' do
        expect(node.os_min_version?(7)).to eq(true)
        expect(node.os_min_version?(8)).to eq(true)
      end

      # This is the back-compat test, this old method was built to only
      # compare the major version, so it will say 8.2 is at least 8.3.
      # Wooo lolz.
      it 'should be min 8.3 (yes, really)' do
        expect(node.os_min_version?(8.3)).to eq(true)
      end

      it 'should not be min 9' do
        expect(node.os_min_version?(9)).to eq(false)
      end
    end

    context 'Chef::Node.os_max_version?' do
      # this is the important case, because this older function takes 8.x == 8
      it 'should be max 8' do
        expect(node.os_max_version?(9)).to eq(true)
      end

      it 'should not be max 7' do
        expect(node.os_max_version?(7)).to eq(false)
      end
    end

    context 'Chef::Node.os_min_version? w/full=true' do
      it 'should be min 8 and 8.2' do
        expect(node.os_min_version?(8, true)).to eq(true)
        expect(node.os_min_version?(8.2, true)).to eq(true)
      end

      it 'should not be min 8.3' do
        expect(node.os_min_version?(8.3, true)).to eq(false)
      end

      it 'should not be min 9 of any sort' do
        expect(node.os_min_version?(9, true)).to eq(false)
        expect(node.os_min_version?(9.1, true)).to eq(false)
      end
    end

    context 'Chef::Node.os_max_version? w/full=true' do
      it 'should be max 9' do
        expect(node.os_max_version?(9, true)).to eq(true)
      end

      it 'should be max 8.2' do
        expect(node.os_max_version?(8.2, true)).to eq(true)
      end

      it 'should not be max 8.1' do
        expect(node.os_max_version?(8.1, true)).to eq(false)
      end
    end
  end

  context 'Ubuntu 24.04' do
    before(:each) do
      node.automatic['platform_version'] = '24.04'
      node.automatic['platform_family'] = 'debian'
      node.automatic['platform'] = 'ubuntu'
    end

    it 'should report correct version' do
      expect(node._self_version).to eq(FB::Version.new('24.04'))
    end

    context 'Chef::Node.os_min_version?' do
      it 'should be min 23 and 24' do
        expect(node.os_min_version?(23)).to eq(true)
        expect(node.os_min_version?(24)).to eq(true)
      end

      # This is the back-compat test, this old method was built to only
      # compare the major version, so it will say 8.2 is at least 8.3.
      # Wooo lolz.
      it 'should be min 24.09 (yes, really)' do
        expect(node.os_min_version?(24.9)).to eq(true)
      end

      it 'should not be min 25' do
        expect(node.os_min_version?(25)).to eq(false)
      end
    end

    context 'Chef::Node.el_min_version?' do
      it 'should not pass even if the version matches (wrong OS)' do
        expect(node.el_min_version?(11)).to eq(false)
      end
    end

    context 'Chef::Node.el_max_version?' do
      it 'should not pass even if the version matches (wrong OS)' do
        expect(node.el_max_version?(99)).to eq(false)
      end
    end

    context 'Chef::Node.os_max_version?' do
      # this is the important case, because this older function takes 8.x == 8
      it 'should be max 24 (yes, really)' do
        expect(node.os_max_version?(24)).to eq(true)
      end

      it 'should not be max 22' do
        expect(node.os_max_version?(22)).to eq(false)
      end
    end

    context 'Chef::Node.os_min_version? w/full=true' do
      it 'should be min 24 and 24.04' do
        expect(node.os_min_version?(24, true)).to eq(true)
        expect(node.os_min_version?(24.04, true)).to eq(true)
      end

      it 'should not be min 24.05' do
        expect(node.os_min_version?(24.05, true)).to eq(false)
      end

      it 'should not be min 25 of any sort' do
        expect(node.os_min_version?(25, true)).to eq(false)
        expect(node.os_min_version?(25.1, true)).to eq(false)
      end
    end

    context 'Chef::Node.os_max_version? w/full=true' do
      it 'should be max 25' do
        expect(node.os_max_version?(25, true)).to eq(true)
      end

      it 'should be max 24.04' do
        expect(node.os_max_version?(24.04, true)).to eq(true)
      end

      it 'should not be max 24.03' do
        expect(node.os_max_version?(24.03, true)).to eq(false)
      end

      it 'should not be max 23 of any sort' do
        expect(node.os_max_version?(23, true)).to eq(false)
        expect(node.os_max_version?(23.9, true)).to eq(false)
      end
    end

    context 'Chef::Node.ubuntu_version?' do
      it 'should handle major versions properly' do
        {
          23 => false,
          24 => true,
          25 => false,
        }.each do |v, r|
          expect(node.ubuntu_version?(v)).to eq(r)
          expect(node.ubuntu_version?(v.to_s)).to eq(r)
        end
      end

      it 'should handle minor versions properly' do
        {
          '23.04' => false,
          '24.01' => false,
          '24.04' => true,
          '24.10' => false,
          '25.04' => false,
        }.each do |v, r|
          expect(node.ubuntu_version?(v)).to eq(r)
          expect(node.ubuntu_version?(v.to_f)).to eq(r)
        end
      end
    end
  end

  context 'Fedora 39' do
    before(:each) do
      node.automatic['platform_version'] = '39'
      node.automatic['platform_family'] = 'fedora'
      node.automatic['platform'] = 'fedora'
    end

    context 'Chef::Node.fedora_version?' do
      it 'handles versions correctly' do
        {
          37 => false,
          38 => false,
          39 => true,
          40 => false,
        }.each do |v, r|
          expect(node.fedora_version?(v)).to eq(r)
          expect(node.fedora_version?(v.to_s)).to eq(r)
        end
      end
    end
  end

  context 'CentOS 9' do
    before(:each) do
      node.automatic['platform_version'] = '9'
      node.automatic['platform_family'] = 'rhel'
      node.automatic['platform'] = 'centos'
    end

    context 'Chef::Node.centos_version?' do
      it 'handles versions correctly' do
        expect(node.centos_version?(8)).to eq(false)
        expect(node.centos_version?(9)).to eq(true)
        expect(node.centos_version?(10)).to eq(false)

        expect(node.centos_version?(9.1)).to eq(false)
        expect(node.centos_version?(9.2)).to eq(false)
      end
    end
  end

  context 'CentOS 9.1' do
    before(:each) do
      node.automatic['platform_version'] = '9.1'
      node.automatic['platform_family'] = 'rhel'
      node.automatic['platform'] = 'centos'
    end

    context 'Chef::Node.centos_version?' do
      it 'handles versions correctly' do
        {
          8 => false,
          9 => true,
          9.0 => false,
          9.1 => true,
          9.2 => false,
        }.each do |v, r|
          expect(node.centos_version?(v)).to eq(r)
          expect(node.centos_version?(v.to_s)).to eq(r)
        end
      end
    end
  end

  context 'Debian sid' do
    before(:each) do
      node.automatic['platform_version'] = 'trixie/sid'
      node.automatic['platform_family'] = 'debian'
      node.automatic['platform'] = 'debian'
    end

    it 'should report correct version' do
      expect(node._self_version).to eq(FB::Version.new('trixie/sid'))
    end

    context 'Chef::Node.debian_min_version?' do
      it 'should be min anything' do
        expect(node.debian_min_version?(999)).to eq(true)
      end
    end
  end

  context 'Arista EOS 4.31' do
    before(:each) do
      node.automatic['platform_version'] = '4.31'
      node.automatic['platform_family'] = 'arista_eos'
      node.automatic['platform'] = 'arista_eos'
    end

    context 'Chef::Node.aristaeos_version_plus?' do
      it 'handles versions correctly' do
        {
          '4.28' => true,
          '4.30' => true,
          '4.31' => true,
          '4.32' => false,
          '4.50' => false,
          '5' => false,
        }.each do |v, r|
          expect(node.aristaeos_version_plus?(v)).to eq(r)
        end
      end
    end
  end
end
