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
  end
end
