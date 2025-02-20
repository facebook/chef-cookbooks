#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
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
  class Bind
    class Helper
      def self.indent(lvl)
        '  ' * lvl
      end

      def self.address_match_key?(key)
        key.start_with?(
          *%w{allow acl blackhole deny keep no response sort match},
        )
      end

      def self.should_quote?(key, val)
        !(%{yes no auto}.include?(val) || address_match_key?(key))
      end

      def self.gen_list_syntax(list)
        '{ ' + list.map { |x| "#{x}; " }.join + '}'
      end

      def self.render_config(buf, config, ilvl = 0)
        istr = indent(ilvl)
        config.each do |key, val|
          case val
          when TrueClass
            buf << "#{istr}#{key} yes;\n"
          when FalseClass
            buf << "#{istr}#{key} no;\n"
          when Integer
            buf << "#{istr}#{key} #{val};\n"
          when String
            buf << "#{istr}#{key} " +
             (should_quote?(key, val) ? "\"#{val}\";\n" : "#{val};\n")
          when Array
            buf << istr
            buf << "#{key} #{gen_list_syntax(val)};\n"
          when Hash
            buf << istr
            buf << "#{key} {\n"
            render_config(buf, val, ilvl + 1)
            buf << istr
            buf << "};\n"
          else
            fail "fb_bind: bad type for value of #{key}: #{val.class}"
          end
        end
      end

      def self.soa_to_val(info)
        "#{info['mname']} #{info['rname']} (\n" +
          "\t\t\t\t#{info['serial']}\t; Serial\n" +
          "\t\t\t\t#{info['refresh']}\t; Refresh\n" +
          "\t\t\t\t#{info['retry']}\t; Retry\n" +
          "\t\t\t\t#{info['expire']}\t; Expire\n" +
          "\t\t\t\t#{info['negative-cache-ttl']}\t; Negative Cache TTL\n" +
          "\t\t)"
      end

      def self.txt_to_val(info)
        return "\"#{info['value']}\"" if info['value'].length <= 255
        chunks = info['value'].scan(/.{1,255}/)
        "(\n" + chunks.map { |x| "\t\t\t\"#{x}\"\n" }.join + "\t\t)"
      end
    end
  end
end
