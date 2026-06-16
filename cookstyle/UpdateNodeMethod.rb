# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates
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

module RuboCop::Cop::Chef::Meta
  class UpdateNodeMethod < Base
    extend AutoCorrector

    MSG = fb_msg('This node method should be updated to its replacement')
    MSG_LVAR = fb_msg(
      'This node method should be updated to its replacement ' +
      '(assuming this is a Chef::Node object)',
    )

    def changes
      cop_config['Changes'] || {}
    end

    def on_send(node)
      return unless node.receiver
      lvar = node.receiver.lvar_type? && node.receiver.source == 'node'
      # A `self` receiver only resolves to Chef::Node helpers inside instance
      # methods. Inside a class method (`def self.foo` or `class << self`),
      # `self` is the class itself, so rewriting e.g. `self.windows?` into
      # `self.chefutils.windows?` would raise NoMethodError at runtime. Only
      # treat a `self` receiver as a node when not inside a singleton method.
      return unless (node.self_receiver? && !inside_singleton_method?(node)) ||
        (node.receiver.send_type? && node.receiver.method?(:node)) ||
        lvar
      replacement_method = changes[node.method_name.to_s]
      return unless replacement_method

      msg = lvar ? MSG_LVAR : MSG
      add_offense(node, :message => msg, :severity => :warning) do |corrector|
        corrector.replace(
          node.loc.selector,
          replacement_method,
        )
      end
    end

    private

    # True when `node` is inside a singleton (class) method, where `self` is the
    # class object rather than a Chef::Node instance. Covers both `def self.foo`
    # and methods under `class << self`. The nearest enclosing method definition
    # wins, so an instance method nested inside a class method is still treated
    # as an instance method.
    def inside_singleton_method?(node)
      method_def = node.each_ancestor(:def, :defs).first
      return false unless method_def
      return true if method_def.defs_type?

      # A plain `def` is also a singleton method when wrapped in `class << self`.
      enclosing_scope = method_def.each_ancestor(
        :sclass, :class, :module, :def, :defs
      ).first
      enclosing_scope&.sclass_type? || false
    end
  end
end
