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

default_action :manage

action :manage do
  node['fb_networksetup']['services'].each do |service, config|
    iface = config['interface']
    unless iface
      fail "fb_networksetup: unknown interface for #{service}"
    end

    addrs = node['network']['interfaces'][iface]['addresses']
    v4_addrs = addrs.select { |_, a| a['family'] == 'inet' }.keys.map do |a|
      IPAddr.new(a)
    end
    v6_addrs = addrs.select { |_, a| a['family'] == 'inet6' }.keys.map do |a|
      IPAddr.new(a)
    end

    v4_config = !config['ipv4'].nil? ? config['ipv4'] : {}
    v6_config = !config['ipv6'].nil? ? config['ipv6'] : {}

    unless v4_config['address'] || v6_config['address']
      fail "fb_networksetup: #{service} (#{iface}) has neither IPv4 nor IPv6 " +
           'address configured, aborting'
    end

    if v4_config['address']
      unless v4_config['netmask'] || v4_config['gateway']
        fail "fb_networksetup: #{service} (#{iface}) has IPv4 but no netmask " +
             'or gateway, aborting'
      end
      unless v4_addrs.include?(IPAddr.new(v4_config['address']))
        execute "Setup IPv4 on #{service}" do
          command "/usr/sbin/networksetup -setmanual #{service} " +
            "#{v4_config['address']} #{v4_config['netmask']} " +
            v4_config['gateway']
        end
      end
    else
      unless v4_addrs.empty?
        execute "Disable IPv4 on #{service}" do
          command "/usr/sbin/networksetup -setv4off #{service}"
        end
      end
    end

    if v6_config['address']
      unless v6_addrs.include?(IPAddr.new(v6_config['address']))
        execute "Setup IPv6 on #{service}" do
          command "/usr/sbin/networksetup -setv6manual #{service} " +
            "#{v6_config['address']} #{v6_config['netmask']} " +
            v6_config['gateway']
        end
      end
    else
      unless v6_addrs.empty?
        execute "Disable IPv6 on #{service}" do
          command "/usr/sbin/networksetup -setv6off #{service}"
        end
      end
    end
  end
end
