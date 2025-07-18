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

module FB
  class NetworkScripts
    def self.len2mask(len)
      mask = ''
      4.times do
        if len > 7
          mask += '255.'
        else
          dec = 255 - (2**(8 - len) - 1)
          mask += dec.to_s + '.'
        end
        len -= 8
        if len < 0
          len = 0
        end
      end
      mask.chop
    end

    def self.v6range2list(start, finish)
      intstart = start.split(':')[-1].hex
      intend = finish.split(':')[-1].hex
      ip_base = start.split(':')[0..-2].join(':')

      ips = []
      (intstart..intend).each do |i|
        # Note that for secondaries, in our case, we pretty much want
        # /128s. Though in reality, it doesn't make much difference.
        ips << "#{ip_base}:#{i.to_s(16)}/128"
      end
      ips
    end

    def self.primary_interface_pause_configured?(node)
      interface = node['fb_network_scripts']['primary_interface']
      interface = interface == 'br0' ? 'eth0' : interface

      current = node['network']['interfaces'][interface]['pause_params']
      pause_settings = node['fb_network_scripts']['pause']

      # pause_settings are a map 'tx'/'rx'/'autonegotiate' => nil, true or false
      if pause_settings.values.all?(&:nil?)
        return true
      end

      pause_settings.each do |pause_type, exp_value|
        next if exp_value.nil?

        if current[pause_type] != exp_value
          return false
        end
      end
      return true
    end
  end
end
