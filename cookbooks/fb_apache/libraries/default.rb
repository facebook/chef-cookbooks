#
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
  class Apache
    # Any exceptions to the normal hash->apache 1:1 mapping
    HANDLERS = {
      '_rewrites' => 'template_rewrite_helper',
    }.freeze

    def self.indentstr(indent)
      '  ' * indent
    end

    # Map a hash to a apache-style syntax
    def self.template_hash_handler(buf, indent, kw, data)
      if HANDLERS.keys.include?(kw)
        self.send(HANDLERS[kw], buf, indent, kw, data)
        return
      end
      buf << indentstr(indent)
      buf << "<#{kw}>\n"
      data.each do |key, val|
        if val.is_a?(String)
          buf << indentstr(indent + 1)
          buf << "#{key} #{val}\n"
        elsif val.is_a?(Hash)
          template_hash_handler(buf, indent + 1, key, val)
        end
      end
      buf << indentstr(indent)
      buf << "</#{kw.split(' ')[0]}>\n"
    end

    # Helper for rewrite syntax
    def self.template_rewrite_helper(buf, _indent, _key, rules)
      rules.each do |name, ruleset|
        buf << indentstr(1)
        buf << "# #{name}\n"
        ruleset['conditions'].each do |cond|
          buf << indentstr(1)
          buf << "RewriteCond #{cond}\n"
        end
        buf << indentstr(1)
        buf << "RewriteRule #{ruleset['rule']}\n\n"
      end
    end

    # given a list of modules return the packages they require
    def self.get_module_packages(mods, pkgs)
      mods.map { |mod| pkgs[mod] }.uniq.compact
    end
  end
end
