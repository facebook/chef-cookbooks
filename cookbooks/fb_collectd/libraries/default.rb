# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

module FB
  # collectd utility functions
  class Collectd
    # Internal helper function to generate /etc/collectd/collectd.conf entries
    def self._gen_collectd_conf_entry(k, v, i = 0)
      indent = ' ' * i
      # For keys with multiple values (i.e. an array for a value) we need to
      # specify the whole line multiple times, so we generate:
      #   key = "foo1"
      #   key = "foo2"
      # and so on.
      if v.is_a?(Array)
        s = ''
        v.each do |vv|
          s += self._gen_collectd_conf_entry(k, vv, i) + "\n"
        end
        return s.chop
      # Hashes are represented with Apache vhost-like configs. The key name
      # will start the block, and everything inside of it is processed like
      # normal (further hashes, arrays, etc. will all be processed properly)
      # and then we close the block.
      elsif v.is_a?(Hash)
        s = "#{indent}<#{k}>\n"
        v.each do |kk, vv|
          s += self._gen_collectd_conf_entry(kk, vv, i + 2) + "\n"
        end
        s += "#{indent}</#{k.split(' ')[0]}>"
        return s
      elsif v.is_a?(TrueClass)
        return "#{indent}#{k} true"
      elsif v.is_a?(FalseClass)
        return "#{indent}#{k} false"
      elsif v.is_a?(Numeric)
        return "#{indent}#{k} #{v}"
      else
        return "#{indent}#{k} \"#{v}\""
      end
    end
  end
end
