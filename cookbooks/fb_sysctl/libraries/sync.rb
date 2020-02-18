# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

module FB
  # tools for the fb_sysctl cookbook
  module Sysctl
    def self.current_settings
      s = Mixlib::ShellOut.new('/sbin/sysctl -a')
      s.run_command
      s.error!

      current = {}
      s.stdout.each_line do |line|
        line.match(/^(\S+)\s*=\s*(.*)$/)
        current[$1] = $2
      end
      current
    end

    def self.normalize(val)
      val.to_s.gsub(/\s+/, ' ')
    end

    def self.incorrect_settings(current, desired)
      out_of_spec = {}
      desired.each do |k, v|
        unless current[k]
          fail "fb_sysctl: Invalid setting #{k}"
        end

        cur_val = normalize(current[k])
        Chef::Log.debug("fb_sysctl: current #{k} = #{cur_val}")
        des_val = normalize(v)
        Chef::Log.debug("fb_sysctl: desired #{k} = #{des_val}")
        unless cur_val == des_val
          out_of_spec[k] = cur_val
        end
      end
      out_of_spec
    end
  end
end
