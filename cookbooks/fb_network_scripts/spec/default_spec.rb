# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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
require_relative '../libraries/rh_int_helpers'

describe FB::NetworkScripts do
  context '#len2mask' do
    it 'should handle class netmasks' do
      FB::NetworkScripts.len2mask(24).should eq('255.255.255.0')
    end

    it 'should handle CIDR netmasks' do
      FB::NetworkScripts.len2mask(27).should eq('255.255.255.224')
    end
  end

  context '#v6range2list' do
    it 'should make a list of IPs' do
      start = 'fe80::202:c9ff:fe4f:0'
      finish = 'fe80::202:c9ff:fe4f:5'
      FB::NetworkScripts.v6range2list(start, finish).should eq(
        [
          'fe80::202:c9ff:fe4f:0/128',
          'fe80::202:c9ff:fe4f:1/128',
          'fe80::202:c9ff:fe4f:2/128',
          'fe80::202:c9ff:fe4f:3/128',
          'fe80::202:c9ff:fe4f:4/128',
          'fe80::202:c9ff:fe4f:5/128',
        ],
      )
    end
  end
end

RSpec.configure do |c|
  c.include FB::NetworkScripts::RHInterfaceHelpers
end

describe FB::NetworkScripts::RHInterfaceHelpers do
  context '#running?' do
    let(:node) { Chef::Node.new }
    it 'should return true for interfaces that are up' do
      int = 'oogabooga0'
      f = "/sys/class/net/#{int}/operstate"
      File.should_receive(:exist?).with(f).and_return(true)
      File.should_receive(:read).with(f).and_return("up\n")
      running?(int, node).should eq(true)
    end

    # most virtual interfaces report 'unknown' when up
    it 'should return true for interfaces that are up/unknown' do
      int = 'oogabooga0'
      f = "/sys/class/net/#{int}/operstate"
      File.should_receive(:exist?).with(f).and_return(true)
      File.should_receive(:read).with(f).and_return("unknown\n")
      running?(int, node).should eq(true)
    end

    it 'should return false for interfaces that are down' do
      int = 'oogabooga0'
      f = "/sys/class/net/#{int}/operstate"
      File.should_receive(:exist?).with(f).and_return(true)
      File.should_receive(:read).with(f).and_return("down\n")
      running?(int, node).should eq(false)
    end

    it 'should return false for interfaces that are non-existent' do
      int = 'oogabooga0'
      f = "/sys/class/net/#{int}/operstate"
      File.should_receive(:exist?).with(f).and_return(false)
      running?(int, node).should eq(false)
    end
  end

  context '#read_ifcfg_file' do
    it 'should ignore comments' do
      f = '/tmp/foof'
      File.should_receive(:read).with(f).and_return("# foo\n# bar\n")
      read_ifcfg(f).should eq({})
    end

    it 'should parse keyval pairs' do
      f = '/tmp/foof'
      File.should_receive(:read).with(f).and_return("KEY=VAL\nKEY2=VAL2\n")
      read_ifcfg(f).should eq({ 'KEY' => 'VAL', 'KEY2' => 'VAL2' })
    end

    it 'should handle quoted values' do
      f = '/tmp/foof'
      File.should_receive(:read).with(f).and_return(
        "KEY=\"VAL\"\nKEY2=\"VAL2\"\n",
      )
      read_ifcfg(f).should eq({ 'KEY' => 'VAL', 'KEY2' => 'VAL2' })
    end

    it 'should handle empty values' do
      f = '/tmp/foof'
      File.should_receive(:read).with(f).and_return(
        "KEY=VAL\nKEY2=\nKEY3=\"\"\n",
      )
      read_ifcfg(f).should eq({ 'KEY' => 'VAL', 'KEY2' => '', 'KEY3' => '' })
    end
  end

  context '#get_changed_keys' do
    it 'should report removed keys' do
      c1 = { 'KEY1' => 'stuff here', 'KEY2' => 'more stuff' }
      c2 = { 'KEY2' => 'more stuff' }
      get_changed_keys(c1, c2).should eq(['KEY1'])
    end

    it 'should report added keys' do
      c1 = { 'KEY2' => 'more stuff' }
      c2 = { 'KEY1' => 'stuff here', 'KEY2' => 'more stuff' }
      get_changed_keys(c1, c2).should eq(['KEY1'])
    end

    it 'should report modified keys' do
      c1 = { 'KEY1' => 'stuff here', 'KEY2' => 'more stuff' }
      c2 = { 'KEY1' => 'different here', 'KEY2' => 'more stuff' }
      get_changed_keys(c1, c2).should eq(['KEY1'])
    end

    it 'should report combinations' do
      c1 = {
        'KEY1' => 'stuff here',
        'KEY2' => 'more stuff',
        'KEY3' => 'same stuff',
      }
      c2 = {
        'KEY2' => 'different here',
        'KEY3' => 'same stuff',
        'KEY4' => 'more stuff',
      }
      get_changed_keys(c1, c2).should eq(['KEY1', 'KEY2', 'KEY4'])
    end

    it 'should see IPv6 addresses with different casing the same' do
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:FACE:0000:00a9:0000',
      }
      get_changed_keys(c1, c2).should eq([])
    end

    it 'should see IPv6 addresses with different expansion the same' do
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0:00a9:0',
      }
      get_changed_keys(c1, c2).should eq([])

      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face::00a9:0',
      }
      get_changed_keys(c1, c2).should eq([])
    end

    it 'should see IPv6 addresses with and without /64 the same' do
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000/64',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      get_changed_keys(c1, c2).should eq([])
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000/64',
      }
      get_changed_keys(c1, c2).should eq([])
    end

    it 'should see IPv6 addresses with different CIDR as different' do
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000/128',
      }
      get_changed_keys(c1, c2).should eq(['IPV6ADDR'])
      c1 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000/128',
      }
      c2 = {
        'IPV6ADDR' => '2401:db00:0021:70dd:face:0000:00a9:0000',
      }
      get_changed_keys(c1, c2).should eq(['IPV6ADDR'])
    end

    it 'should see IPV6 secondary address with different casing the same' do
      c1 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:db00:0021:70dd:face:0000:00a9:0000/64 ' +
            '2803:6080:c898:74a9::1/64',
      }
      c2 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:DB00:0021:70DD:FACE:0000:00A9:0000/64 ' +
            '2803:6080:C898:74A9::1/64',
      }
      get_changed_keys(c1, c2).should eq([])
    end

    it 'should see IPV6 secondary address with different expansion the same' do
      c1 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:db00:0021:70dd:face:0000:00a9:0000/64 ' +
            '2803:6080:c898:74a9::1/64',
      }
      c2 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:db00:0021:70dd:face:0:00a9:0/64 ' +
            '2803:6080:c898:74a9::1/64',
      }
      get_changed_keys(c1, c2).should eq([])

      c1 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:db00:0021:70dd:face:0000:00a9:0000/64 ' +
            '2803:6080:c898:74a9::1/64',
      }
      c2 = {
        'IPV6ADDR_SECONDARIES' =>
          '2401:db00:0021:70dd:face::00a9:0/64 ' +
            '2803:6080:c898:74a9::1/64',
      }
      get_changed_keys(c1, c2).should eq([])
    end
  end

  context '#get_v6addrs' do
    let(:node) { Chef::Node.new }
    it 'should report v6 addresses' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        'fe80::1' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      get_v6addrs(node, iface).should eq(['fe80::1/64'])
    end

    it 'should not report local v6 addresses' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        'fe80::1' => {
          'scope' => 'local',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      get_v6addrs(node, iface).should eq([])
    end

    it 'should not report v4 addresses' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        'fe80::1' => {
          'scope' => 'Link',
          'family' => 'inet',
          'prefixlen' => '64',
        },
      }
      get_v6addrs(node, iface).should eq([])
    end
  end

  context '#get_v6_changes' do
    let(:node) { Chef::Node.new }
    it 'should not remove primary addr' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        '2401:db00:11:d0d8:face:0:47:0' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      config = {
        'ipv6' => '2401:db00:11:d0d8:face:0:47:0',
      }
      get_v6_changes(node, iface, config).should eq([Set.new, Set.new])
    end

    it 'should not remove primary addr even if formatted differently' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        # 0-padded
        '2401:db00:0011:d0d8:face:0000:0047:0' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      config = {
        'ipv6' => '2401:db00:11:d0d8:face:0:47:0',
      }
      get_v6_changes(node, iface, config).should eq([Set.new, Set.new])
    end

    it 'should add extra addresses' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        '2401:db00:11:d0d8:face:0:47:0' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      config = {
        'ipv6' => '2401:db00:11:d0d8:face:0:47:0',
        'v6secondaries' => [
          '2401:ffff:6969:0:0:0:0:4/64',
        ],
      }
      get_v6_changes(node, iface, config).should eq(
        [Set.new(['2401:ffff:6969::4/64']), Set.new],
      )
    end

    it 'should remove extra addresses' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        '2401:db00:11:d0d8:face:0:47:0' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
        '2401:ffff:6969:0:0:0:0:4' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
      }
      config = {
        'ipv6' => '2401:db00:11:d0d8:face:0:47:0',
      }
      get_v6_changes(node, iface, config).should eq(
        [Set.new, Set.new(['2401:ffff:6969::4/64'])],
      )
    end

    it 'should handle complex combinations' do
      iface = 'ooga0'
      node.default['network']['interfaces'][iface]['addresses'] = {
        # primary address
        '2401:db00:11:d0d8:face:0:47:0' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
        # address that is staying, but not in compacted format
        '2401:ffff:6969:0:0:0:0:4' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
        # address that is being removed
        '2401:1111:0666:0:0:0:0:99' => {
          'scope' => 'global',
          'family' => 'inet6',
          'prefixlen' => '64',
        },
        'fe80::202:c9ff:fe4f:bae0' => {
          'family' => 'inet6',
          'prefixlen' => '64',
          'scope' => 'Link',
        },
      }
      config = {
        'ipv6' => '2401:db00:11:d0d8:face:0:47:0',
        'v6secondaries' => [
          # already here and staying
          '2401:ffff:6969:0:0:0:0:4/64',
          # being added
          '2401:69ff:6669:0:0:0:0:8/64',
        ],

      }
      get_v6_changes(node, iface, config).should eq(
        [
          Set.new(['2401:69ff:6669::8/64']),
          Set.new(['2401:1111:666::99/64']),
        ],
      )
    end
  end
end
