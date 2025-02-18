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
  class SpamAssassin
    class TemplateHelper
      def self.indentstr(indent)
        '  ' * indent
      end

      def self.render(buf, indent, key, val)
        if val.is_a?(Hash)
          buf << indentstr(indent)
          buf << "#{key}\n"
          val.each do |subkey, subval|
            render(buf, indent+1, subkey, subval)
          end
          buf << 'endif'
        elsif val.is_a?(Array)
          val.each do |v|
            buf << indentstr(indent)
            buf << "#{key} #{v}\n"
          end
        else
          buf << indentstr(indent)
          buf << "#{key} #{val}\n"
        end
      end
    end
  end
end
