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

require 'set'
require 'ipaddr'

module FB
  class NetworkScripts
    module RHInterfaceHelpers
      # Walk all notifications that are queued
      def will_restart_network?(run_context)
        root_run_context = run_context.root_run_context
        root_run_context.delayed_notification_collection.each_value do |notif|
          notif.each do |n|
            will_run = n.notifying_resource.updated_by_last_action?
            name = n.resource
            if name.to_s == 'service[network]' && will_run
              return true
            end
          end
        end
        false
      end

      def queue_update_ips(run_context, new_resource)
        notification = Chef::Resource::Notification.new(
          new_resource,
          :update_ips,
          new_resource,
        )
        run_context.root_run_context.add_delayed_action(notification)
      end

      def queue_update_mtu(run_context, new_resource)
        notification = Chef::Resource::Notification.new(
          new_resource,
          :update_mtu,
          new_resource,
        )
        run_context.root_run_context.add_delayed_action(notification)
      end

      def running?(interface, node)
        # This function uses the /sys/class/net/<interface>/flags to determine
        # the state of the interface. An interface is considered DOWN
        # only if it is administratively down and not operationally down.

        flagfile = "/sys/class/net/#{interface}/flags"
        if interface.include?(':')
          # /sys does not have info on sub-interfaces.
          #
          # So, if we are a sub-interface, see if Ohai saw us, and then
          # check our base interface is still up
          unless node['network']['interfaces'][interface]
            return false
          end
          flagfile = "/sys/class/net/#{interface.split(':')[0]}/flags"
        end

        return false unless ::File.exist?(flagfile)

        flags = ::File.read(flagfile).strip
        # last bit == "1" means UP, "0" means DOWN
        return flags.hex & 0x1 == 1
      end

      def read_ifcfg(file)
        d = {}
        Chef::Log.debug("fb_network_scripts: reading #{file}")
        cont = false
        prevline = ''
        ::File.read(file).each_line do |line|
          Chef::Log.debug("fb_network_scripts: --> line: #{line}")
          next if line.start_with?('#')
          line.strip!
          if line.end_with?('\\')
            prevline += line[0..-2]
            cont = true
            next
          end
          if cont
            line = prevline + line
            prevline = ''
            cont = false
          end
          key, val = line.split('=')
          val = '' if val.nil?
          # remove quoting
          if !val.empty? && val[0] == '"' && val[-1] == '"'
            val = val[1..-2]
          end
          d[key] = val
        end
        d
      end

      def canonicalize_ipv6(addr)
        # the default cidr is /64
        # See: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s1-networkscripts-interfaces
        ip, cidr = addr.split('/', 2)
        cidr = '64' if cidr.nil?
        "#{IPAddr.new(ip)}/#{cidr}"
      end

      # When building IP objects we want to fail only if the *new* address
      # fails parsing, not the old one, so we can fix stuff
      def get_ip_object(str, failok = false)
        canonicalize_ipv6(str)
      rescue IPAddr::InvalidAddressError => e
        msg = "fb_network_scripts: Failed to parse IPv6 address #{str}"
        if failok
          Chef::Log.warn(
            "#{msg}, but told failure is OK, so returning nil (#{e})",
          )
          return nil
        end
        raise "#{msg}: #{e}"
      end

      def get_changed_keys(current, new)
        changed_keys = []
        Chef::Log.debug("fb_network_scripts: current #{current}, new #{new}")

        current_keys = Set.new(current.keys)
        new_keys = Set.new(new.keys)

        added_keys = new_keys - current_keys
        removed_keys = current_keys - new_keys

        changed_keys += added_keys.to_a unless added_keys.empty?
        changed_keys += removed_keys.to_a unless removed_keys.empty?

        common_keys = current_keys & new_keys
        common_keys.each do |key|
          case key
          when 'IPV6ADDR'
            have = get_ip_object(current[key], true)
            want = get_ip_object(new[key])
            changed_keys << key unless have == want
          when 'IPV6ADDR_SECONDARIES'
            have = Set.new(
              current[key].split.sort.map { |x| get_ip_object(x, true) },
            )
            want = Set.new(new[key].split.sort.map { |x| get_ip_object(x) })
            changed_keys << key unless have == want
          else
            changed_keys << key unless current[key] == new[key]
          end
        end
        Chef::Log.debug("fb_network_scripts: changed is #{changed_keys}")
        changed_keys.sort.uniq
      end

      def get_v6addrs(node, interface)
        node['network']['interfaces'][interface]['addresses'].
          to_hash.map do |addr, info|
          next unless info['family'] == 'inet6'
          next unless info['scope'].casecmp('global').zero?
          next if info['tags'] && info['tags'].include?('dynamic')
          # Normalize v6 format
          "#{IPAddr.new(addr)}/#{info['prefixlen']}"
        end.compact
      end

      def do_address_change(action, interface, addr)
        # preferred_lft 0 means we'll never auto-select this
        # for outgoing connections. we can still accept connections
        # on these addresses

        # NOTE: this requires code in ifup-local to set life-time zero
        # for secondaries on machine boot
        cmd = "ip -6 addr #{action} #{addr} dev #{interface} preferred_lft 0"
        Chef::Log.debug("fb_network_scripts: Running: #{cmd}")
        Mixlib::ShellOut.new(cmd).run_command.error!
      end

      def add_v6addrs(interface, to_add)
        to_add.each do |addr|
          Chef::Log.info(
            "fb_network_scripts_redhat_interface[#{interface}] Adding #{addr}",
          )
          do_address_change('add', interface, addr)
        end
      end

      def remove_v6addrs(interface, to_remove)
        to_remove.each do |addr|
          Chef::Log.info(
            "fb_network_scripts_redhat_interface[#{interface}] Removing " +
            addr.to_s,
          )
          do_address_change('del', interface, addr)
        end
      end

      def get_v6_changes(node, interface, config)
        # get current secondary addresses
        current = Set.new(get_v6addrs(node, interface))
        Chef::Log.debug("fb_network_scripts: All current v6 addrs: #{current}")
        # We need to ignore the ipv6 primary, so we remove it from the
        # addresses list
        current.delete(canonicalize_ipv6(config['ipv6']))

        new = Set.new(
          config.fetch('v6secondaries', []).map do |x|
            canonicalize_ipv6(x)
          end,
        )

        to_add = new - current
        to_remove = current - new
        [to_add, to_remove]
      end

      def set_mtu(interface, mtu)
        cmd = "ip link set dev #{interface} mtu #{mtu}"
        Chef::Log.debug("fb_network_scripts: Running: #{cmd}")
        Mixlib::ShellOut.new(cmd).run_command.error!
      end
    end
  end
end
