# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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
