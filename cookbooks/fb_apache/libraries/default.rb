#
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
  class Apache
    # Any exceptions to the normal hash->apache 1:1 mapping
    HANDLERS = {
      '_rewrites' => 'template_rewrite_helper',
    }.freeze

    def self.indentstr(indent)
      '  ' * indent
    end

    def self.render_apache_conf(buf, depth, config)
      config.each do |kw, val|
        if HANDLERS.keys.include?(kw)
          self.send(HANDLERS[kw], buf, depth, val)
          next
        end

        indent = indentstr(depth)

        case val
        when String, Integer
          buf << indent
          buf << "#{kw} #{val}\n"

        when Array
          val.each do |entry|
            buf << indent
            buf << "#{kw} #{entry}\n"
          end

        when Hash
          buf << indent
          buf << "<#{kw}>\n"

          render_apache_conf(buf, depth + 1, val)

          buf << indent
          buf << "</#{kw.split[0]}>\n"

        else
          fail "fb_apache: bad type for value of #{kw}: #{val.class}"
        end
      end
    end

    # Helper for rewrite syntax
    def self.template_rewrite_helper(buf, depth, rules)
      indent = indentstr(depth)

      rules.each do |name, ruleset|
        buf << indent
        buf << "# #{name}\n"

        ruleset['conditions']&.each do |cond|
          buf << indent
          buf << "RewriteCond #{cond}\n"
        end

        buf << indent
        buf << "RewriteRule #{ruleset['rule']}\n\n"
      end
    end

    # given a list of modules return the packages they require
    def self.get_module_packages(mods, pkgs)
      mods.map { |mod| pkgs[mod] }.uniq.compact
    end
  end
end
