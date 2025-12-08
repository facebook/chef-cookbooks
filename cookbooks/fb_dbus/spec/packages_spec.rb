# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
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

recipe 'fb_dbus::packages', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  context 'when manage_packages is false' do
    it 'does not upgrade any packages' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_dbus']['manage_packages'] = false
      end
      expect(chef_run).not_to upgrade_package(%w{dbus dbus-libs})
      expect(chef_run).not_to upgrade_package(%w{dbus-tools})
      expect(chef_run).not_to upgrade_package('dbus-broker')
    end
  end

  context 'when manage_packages is true' do
    it 'upgrades dbus and dbus-libs packages' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_dbus']['manage_packages'] = true
      end
      expect(chef_run).to upgrade_package(%w{dbus dbus-libs})
    end

    context 'when manage_dbus_tools is false' do
      it 'does not upgrade dbus-tools' do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_dbus']['manage_packages'] = true
          node.default['fb_dbus']['manage_dbus_tools'] = false
        end
        expect(chef_run).not_to upgrade_package(%w{dbus-tools})
      end
    end

    context 'when manage_dbus_tools is true' do
      it 'upgrades dbus-tools' do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_dbus']['manage_packages'] = true
          node.default['fb_dbus']['manage_dbus_tools'] = true
        end
        expect(chef_run).to upgrade_package(%w{dbus-tools})
      end
    end

    context 'when implementation is not dbus-broker' do
      it 'does not upgrade dbus-broker' do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_dbus']['manage_packages'] = true
          node.default['fb_dbus']['implementation'] = 'dbus-daemon'
        end
        expect(chef_run).not_to upgrade_package('dbus-broker')
      end
    end

    context 'when implementation is dbus-broker' do
      it 'upgrades dbus-broker' do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_dbus']['manage_packages'] = true
          node.default['fb_dbus']['implementation'] = 'dbus-broker'
        end
        expect(chef_run).to upgrade_package('dbus-broker')
      end
    end
  end
end
