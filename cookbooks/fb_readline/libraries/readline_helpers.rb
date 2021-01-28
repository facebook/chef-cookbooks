# Copyright (c) 2021-present, Facebook, Inc.
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
  class Readline
    def self.render_value(value)
      case value
      when 'on', 'On', true
        out = 'on'
      when 'off', 'Off', false
        out = 'off'
      else
        out = value
      end
      out
    end

    def self.render_config(key_bindings, variables)
      out = []
      variables.each do |key, val|
        out << "set #{key} #{self.render_value(val)}"
      end
      key_bindings.each do |key, val|
        out << "\"#{key}\": #{val}"
      end
      out
    end

    def self.render_mode_config(mode, key_bindings, variables)
      out = ["$if mode=#{mode}"]
      out += self.render_config(key_bindings, variables)
      out << '$endif'
      out
    end

    def self.render_term_config(term, key_bindings, variables)
      out = ["$if term=#{term}"]
      out += self.render_config(key_bindings, variables)
      out << '$endif'
      out
    end
  end
end
