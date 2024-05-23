# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2023-present, Facebook, Inc.
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

recipe 'fb_networkd::default', :unsupported => [:mac_os_x] do |tc|

  context 'basic networkd setup' do
    iface = 'eth0'
    cached(:chef_run) do
      tc.chef_run(
        :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
      ) do |node|
        allow(node).to receive(:systemd?).and_return(true)

        # These enable the fb_helpers_gated_template resources
        allow(node).to receive(:interface_change_allowed?).and_return(true)
        allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
        allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
      end.converge(described_recipe) do |node|
        node.default['fb_networkd']['networks'][iface] = {
          'priority' => 1,
          'config' => {
            'Network' => {
              'Address' => [
                '2001:db00::1/64',
                '192.168.1.1/24',
                '2401:db00::1/64',
              ],
              'VLAN' => [
                "#{iface}.4092",
                "#{iface}.4088",
              ],
            },
            'Address' => [
              {
                'Address' => '2001:db00::1/64',
                'PreferredLifetime' => 'infinity',
              },
              {
                'Address' => '2401:db00::1/64',
                'PreferredLifetime' => '0',
              },
            ],
          },
        }

        node.default['fb_networkd']['links'][iface]['config']['Match'][
          'OriginalName'] = iface

        node.default['fb_networkd']['devices']["#{iface}.4092"]['config']['NetDev'][
          'Kind'] = 'vlan'
        node.default['fb_networkd']['devices']["#{iface}.4088"]['config']['NetDev'][
          'Kind'] = 'vlan'
        node.default['fb_networkd']['devices']["#{iface}.4092"]['config']['VLAN'][
          'Id'] = 4092
        node.default['fb_networkd']['devices']["#{iface}.4088"]['config']['VLAN'][
          'Id'] = 4088

        node.default['fb_networkd']['devices']['tap0']['config']['NetDev'][
          'Kind'] = 'tap'
      end
    end

    it 'should create networkd config files' do
      # Primary interfaces gets priority 1
      expect(chef_run).to render_file("/etc/systemd/network/1-fb_networkd-#{iface}.network").
        with_content(tc.fixture("1-fb_networkd-#{iface}.network"))

      expect(chef_run).to render_file("/etc/systemd/network/1-fb_networkd-#{iface}.link").
        with_content(tc.fixture("1-fb_networkd-#{iface}.link"))

      expect(chef_run).to render_file("/etc/systemd/network/50-fb_networkd-#{iface}.4092.netdev").
        with_content(tc.fixture("50-fb_networkd-#{iface}.4092.netdev"))

      expect(chef_run).to render_file("/etc/systemd/network/50-fb_networkd-#{iface}.4088.netdev").
        with_content(tc.fixture("50-fb_networkd-#{iface}.4088.netdev"))

      # default device priority is 50
      expect(chef_run).to render_file('/etc/systemd/network/50-fb_networkd-tap0.netdev').
        with_content(tc.fixture('50-fb_networkd-tap0.netdev'))
    end
  end

  context 'use of bad ip addresses' do
    it 'should fail the run with bad Network Address' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Network' => {
                'Address' => [
                  '2001::db00:1/64',
                  '2001::bad1::1/64', # Extra colon
                ],
              },
            },
          }
        end
      end.to raise_error(RuntimeError, %r{fb_networkd:.*Trying to use bad Network Address IP: '2001::bad1::1/64'.*})
    end

    it 'should not fail the run with good Network Address as a string' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Network' => {
                'Address' => '2001::db00:1/64',
              },
            },
          }
        end
      end
    end

    it 'should fail the run with bad Network Address as a string' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Network' => {
                'Address' => '2001::db0z:1/64',
              },
            },
          }
        end
      end.to raise_error(RuntimeError, %r{fb_networkd:.*Trying to use bad Network Address IP: '2001::db0z:1/64'.*})
    end

    it 'should fail the run with bad Address Address' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'config' => {
              'Address' => [
                {
                  'Address' => '2001:db00::1/64',
                  'PreferredLifetime' => 'infinity',
                },
                {
                  'Address' => '2001::bad1::1/64',
                  'PreferredLifetime' => 'infinity',
                },
              ],
            },
          }
        end
      end.to raise_error(RuntimeError, %r{fb_networkd:.*Trying to use bad Address IP: '2001::bad1::1/64'.*})
    end

    it 'should fail the run with bad Route Gateway' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Route' => [
                {
                  'Gateway' => '2001::bad1::1',
                  'Source' => '::/0',
                  'Destination' => '::/0',
                  'Metric' => '1',
                },
              ],
            },
          }
        end
      end.to raise_error(RuntimeError, /fb_networkd:.*Trying to use bad .*bad1.*/)
    end
    it 'should fail the run with bad Route Source' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Route' => [
                {
                  'Gateway' => '2001::db00:1',
                  'Source' => '::/bad0',
                  'Destination' => '::/0',
                  'Metric' => '1',
                },
              ],
            },
          }
        end
      end.to raise_error(RuntimeError, /fb_networkd:.*Trying to use bad .*bad0.*/)
    end
    it 'should fail the run with bad Route Destination' do
      expect do
        tc.chef_run(
          :step_into => ['fb_networkd', 'fb_helpers_gated_template'],
        ) do |node|
          allow(node).to receive(:systemd?).and_return(true)

          # These enable the fb_helpers_gated_template resources
          allow(node).to receive(:interface_change_allowed?).and_return(true)
          allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
          allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
        end.converge(described_recipe) do |node|
          node.default['fb_networkd']['networks']['eth0'] = {
            'priority' => 1,
            'config' => {
              'Route' => [
                {
                  'Gateway' => '2001::db00:1',
                  'Source' => '::/0',
                  'Destination' => '::/bad2',
                  'Metric' => '1',
                },
              ],
            },
          }
        end
      end.to raise_error(RuntimeError, /fb_networkd:.*Trying to use bad .*bad2.*/)
    end
  end
end
