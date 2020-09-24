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

class Chef
  # Provide some node methods
  class Node
    # Returns true if the address provided as input is configured in any of the
    # network interfaces.
    def ip?(iface_address)
      self['network']['interfaces'].to_hash.each_value do |value|
        if value['addresses'] && value['addresses'][iface_address]
          return true
        end
      end
      false
    end

    def find_next_sub_interface(int_type)
      num = -1
      base_int = "#{int_type}0"
      self['fb_network_scripts']['interfaces'].to_hash.each_key do |iface|
        next unless iface.start_with?(base_int)
        (_, subnum) = iface.split(':')
        subnum = subnum ? subnum.to_i : 0
        num = subnum if subnum > num
      end
      num += 1
      # If the sub_interface is 0, our standard is that we don't include it
      interface = base_int
      interface << ":#{num}" if num > 0
      interface
    end

    def find_next_interface(int_type)
      num = -1
      self['fb_network_scripts']['interfaces'].to_hash.each_key do |iface|
        next unless iface.start_with?(int_type)
        m = /\w+(\d+)/.match(iface)
        if m
          intnum = m[1].to_i
          num = intnum if intnum > num
        end
      end
      num += 1
      interface = "#{int_type}#{num}"
      interface
    end

    def nw_changes_allowed?
      method = node['fb_network_scripts']['network_changes_allowed_method']
      if method
        return method.call(node)
      else
        return @nw_changes_allowed unless @nw_changes_allowed.nil?
        @nw_changes_allowed = node.firstboot_any_phase? ||
        ::File.exist?(::FB::NetworkScripts::NW_CHANGES_ALLOWED)
      end
    end

    # We can change interface configs if nw_changes_allowed? or we are operating
    # on a DSR VIP
    def interface_change_allowed?(interface)
      method = node['fb_network_scripts']['interface_change_allowed_method']
      if method
        return method.call(node, interface)
      else
        return self.nw_changes_allowed? ||
          ['ip6tnl0', 'tunlany0', 'tunl0'].include?(interface) ||
          interface.match(Regexp.new('^tunlany\d+:\d+'))
      end
    end

    def interface_start_allowed?(interface)
      method = node['fb_network_scripts']['interface_start_allowed_method']
      if method
        return method.call(node, interface)
      else
        return self.interface_change_allowed?(interface)
      end
    end

    def eth_is_affinitized?
      # we only care about ethernet MSI vectors
      # mlx is special cased because of their device naming convention
      r = /^(eth(.*[Rr]x|\d+-\d+)|mlx4-\d+@.*|mlx5_comp\d+@.*)/

      irqs = node['interrupts']['irq'].select do |_irq, v|
        v['device'] && r.match?(v['device']) &&
          v['type'] && v['type'].end_with?('MSI')
      end
      if irqs.empty?
        Chef::Log.debug(
          'fb_network_scripts: no eth MSI vectors found, this host does ' +
          'not need affinity',
        )
        return true
      end
      default_affinity = node['interrupts']['smp_affinity_by_cpu']
      # When all interrupts are affinitized, smp_affinity will be different
      # from the default one, and won't be global. Global technically says
      # that interrupts can be processed on all CPUs, but in reality what's
      # going to happen is that it'll *always* be processed by the lowest
      # numbered CPU, which is a problem when you have multiple IRQs in play.
      affinitized_irqs = irqs.reject do |_irq, v|
        my_affinity = v['smp_affinity_by_cpu']
        my_affinity == default_affinity ||
          my_affinity == my_affinity.select do |_cpu, is_affinitized|
            is_affinitized
          end
      end
      if irqs == affinitized_irqs
        Chef::Log.info(
          "fb_network_scripts: all #{irqs.size} MSI eth rx IRQs are " +
          'affinitized to CPUs.',
        )
        return true
      else
        Chef::Log.warn(
          "fb_network_scripts: only #{affinitized_irqs.size}/#{irqs.size} " +
          'MSI eth rx IRQs are affinitized to CPUs',
        )
        return false
      end
    end
  end
end
