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
#

require './spec/spec_helper'
require_relative '../libraries/default'

describe FB::Iptables do
  let(:void_rule) { {} }
  let(:v4_rule) { { 'ip' => 4 } }
  let(:v6_rule) { { 'ip' => [6] } }
  let(:v46_rule) { { 'ip' => [4, 6] } }

  describe '#rule_supports_ip_version?' do
    it 'defaults to [4,6]' do
      expect(FB::Iptables.rule_supports_ip_version?(void_rule, 4)).to be true
      expect(FB::Iptables.rule_supports_ip_version?(void_rule, 4)).to be true
    end
    it 'supports Integer' do
      expect(FB::Iptables.rule_supports_ip_version?(v4_rule, 4)).to be true
      expect(FB::Iptables.rule_supports_ip_version?(v4_rule, 6)).to be false
    end
    it 'supports Array' do
      expect(FB::Iptables.rule_supports_ip_version?(v6_rule, 4)).to be false
      expect(FB::Iptables.rule_supports_ip_version?(v6_rule, 6)).to be true
      expect(FB::Iptables.rule_supports_ip_version?(v46_rule, 4)).to be true
      expect(FB::Iptables.rule_supports_ip_version?(v46_rule, 6)).to be true
    end
  end
end

recipe 'fb_iptables::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  it 'FB::Iptables::TemplateHelpers::each_table yields |table,chains|' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_iptables']['filter']['only'] = 4
    end
    FB::Iptables.each_table(4, chef_run.node) do |table_name, chains|
      expect(FB::Iptables::TABLES_AND_CHAINS.keys.include?(table_name)).
        to be true
      x = chef_run.node['fb_iptables'][table_name].to_hash
      x.delete('only')
      expect(chains).to eq(x)
    end
    FB::Iptables.each_table(6, chef_run.node) do |table_name, _chains|
      expect(table_name).not_to eq('filter')
    end
  end

  it 'creates a default /etc/sysconfig/ip[6]tables' do
    chef_run.converge(described_recipe)
    expect(chef_run).to render_file('/etc/sysconfig/iptables').
      with_content(tc.fixture('iptables_min'))
    expect(chef_run).to render_file('/etc/sysconfig/ip6tables').
      with_content(tc.fixture('iptables_min'))
  end

  it 'change default policies' do
    chef_run.converge(described_recipe) do |node|
      FB::Iptables::TABLES_AND_CHAINS.each do |t, chains|
        chains.each do |c|
          node.default['fb_iptables'][t][c]['policy'] = 'DROP'
        end
      end
    end
    expect(chef_run).to render_file('/etc/sysconfig/iptables').
      with_content(tc.fixture('iptables_drop'))
    expect(chef_run).to render_file('/etc/sysconfig/ip6tables').
      with_content(tc.fixture('iptables_drop'))
  end

  it 'complex ruleset' do
    chef_run.converge(described_recipe) do |node|
      {
        'test_1' => {
          'rule' => '-p udp -j REJECT',
        },
        'test_2' => {
          'ip' => 4,
          'rules' => [
            '-p udp -s 192.168.0.1 -j DROP',
            '-p udp -s 192.168.0.2 -j DROP',
          ],
        },
        'test_3' => {
          'ip' => [6],
          'rule' => '-p udp -s 2a03:2880:2130:cf05:face:b00c::3 -j DROP',
        },
      }.each do |name, rule|
        node.default['fb_iptables']['filter']['INPUT']['rules'][name] =
          rule
      end
    end
    expect(chef_run).to render_file('/etc/sysconfig/iptables').
      with_content(tc.fixture('iptables_complex'))
    expect(chef_run).to render_file('/etc/sysconfig/ip6tables').
      with_content(tc.fixture('ip6tables_complex'))
  end

  it 'multiple chain with ruleset' do
    chef_run.converge(described_recipe) do |node|
      {
        'test_1' => {
          'rule' => '-p udp -j REJECT',
        },
        'test_2' => {
          'ip' => 4,
          'rules' => [
            '-p udp -s 192.168.0.1 -j DROP',
            '-p udp -s 192.168.0.2 -j DROP',
          ],
        },
        'test_3' => {
          'rule' => '-p tcp --dport 3306 -j LOG_DB',
        },
      }.each do |name, rule|
        node.default['fb_iptables']['filter']['INPUT']['rules'][name] =
          rule
      end
      {
        'test_4' => {
          'ip' => 4,
          'rules' => [
            '-p tcp -j REJECT --reject-with tcp-reset',
          ],
        },
        'test_5' => {
          'ip' => 6,
          'rules' => [
            '-j LOG --log-prefix db-packet-dropped: --log-level 4',
          ],
        },
      }.each do |name, rule|
        node.default['fb_iptables']['filter']['LOG_DB']['rules'][name] =
          rule
      end
    end
    expect(chef_run).to render_file('/etc/sysconfig/iptables').
      with_content(tc.fixture('iptables_multi_chain'))
    expect(chef_run).to render_file('/etc/sysconfig/ip6tables').
      with_content(tc.fixture('ip6tables_multi_chain'))
  end
end
