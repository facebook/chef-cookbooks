# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
      return out_of_spec
    end
  end
end
