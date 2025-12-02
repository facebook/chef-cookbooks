#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2025-present, Phil Dibowitz
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
  class InfluxDB
    def self.indentstr(indent)
      '  ' * indent
    end

    def self.handle_raw_val(val)
      val.is_a?(String) ? "\"#{val}\"" : val.to_s
    end

    def self.template_hash_helper(buf, indent, data)
      data.each do |key, val|
        buf << indentstr(indent + 1)
        case val
        when Array
          buf << "#{key} = [\n"
          val.each do |item|
            buf << indentstr(indent + 2)
            buf << "#{handle_raw_val(item)},\n"
          end
          buf << indentstr(indent + 1)
          buf << "]\n"
        when Hash
          template_hash_helper(buf, indent + 1, data)
        else
          buf << "#{key} = #{handle_raw_val(val)}\n"
        end
      end
    end
  end
end
