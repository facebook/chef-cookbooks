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
  class Nscd
    def self.nscd_enabled?(node)
      %w{passwd group hosts}.any? do |table|
        node['fb_nscd'][table]['enable-cache'] == true ||
          node['fb_nscd'][table]['enable-cache'] == 'yes'
      end
    end

    def self._render_value(value)
      if value.is_a?(TrueClass)
        'yes'
      elsif value.is_a?(FalseClass)
        'no'
      else
        value.to_s
      end
    end

    def self._global_config(property, value)
      format('%-25s %s', property, FB::Nscd._render_value(value))
    end

    def self._table_config(property, table, value)
      format('%-25s %-9s %-8s', property, table, FB::Nscd._render_value(value))
    end
  end
end
