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
  # APT utility functions
  class Apt
    # Internal helper function to generate /etc/apt.conf entries
    def self._gen_apt_conf_entry(k, v, i = 0)
      indent = ' ' * i
      if v.is_a?(Hash)
        s = "\n#{indent}#{k} {"
        v.each do |kk, vv|
          s += self._gen_apt_conf_entry(kk, vv, i + 2)
        end
        s += "\n#{indent}};"
        return s
      elsif v.is_a?(Array)
        s = ''
        v.each do |vv|
          s += self._gen_apt_conf_entry(k, vv, i)
        end
        return s
      elsif v.is_a?(TrueClass)
        return "\n#{indent}#{k} \"true\";"
      elsif v.is_a?(FalseClass)
        return "\n#{indent}#{k} \"false\";"
      else
        return "\n#{indent}#{k} \"#{v}\";"
      end
    end
  end
end
