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
    def self.sysctl_in_sync?(node)
      # Get current settings
      s = Mixlib::ShellOut.new('/sbin/sysctl -a')
      s.run_command
      unless s.exitstatus == 0
        Chef::Log.warn("fb_sysctl: error running /sbin/sysctl -a: #{s.stderr}")
        Chef::Log.debug("STDOUT: #{s.stdout}")
        Chef::Log.debug("STDERR: #{s.stderr}")
        # We couldn't collect current state so cowardly assume all is well
        return true
      end

      current = {}
      s.stdout.split("\n").each do |line|
        line.gsub(/\s+/, ' ').match(/^(\S+) = (.*)$/)
        current[$1] = $2
      end

      # Check desired settings, assume we're in sync unless we find we are not
      insync = true
      node['fb_sysctl'].to_hash.each do |k, v|
        Chef::Log.debug("fb_sysctl: current #{k} = #{current[k]}")
        desired = v.to_s.gsub(/\s+/, ' ')
        Chef::Log.debug("fb_sysctl: desired #{k} = #{desired}")
        unless desired == current[k]
          insync = false
          Chef::Log.info(
            "fb_sysctl: #{k} current value \"#{current[k]}\" does " +
            "not match desired value \"#{desired}\"",
          )
        end
      end
      return insync
    end
  end
end
