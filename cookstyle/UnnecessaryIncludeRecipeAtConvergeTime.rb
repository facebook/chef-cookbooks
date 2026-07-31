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
  class UnnecessaryIncludeRecipeAtConvergeTime < Base
    extend AutoCorrector

    MSG = fb_msg('include_recipe_at_converge_time should only be used when there are resource guards')

    def_node_search :guarded?, <<-PATTERN
      (send nil? {:only_if :not_if} ...)
    PATTERN

    RESTRICT_ON_SEND = [:include_recipe_at_converge_time].freeze
    def on_send(node)
      block = node.parent if node.parent&.block_type? && node.parent.send_node.equal?(node)
      body = block&.body
      return if body && guarded?(body)

      # A block body without a guard can still hold properties `include_recipe`
      # cannot express - notifications, a non-default action, the `recipe`
      # name property - so those get flagged for a human to unpick.
      return add_offense(node.loc.selector, :severity => :warning) if body

      add_offense(node.loc.selector, :severity => :warning) do |corrector|
        if block
          corrector.replace(block, "include_recipe #{node.arguments.map(&:source).join(', ')}")
        else
          corrector.replace(node.loc.selector, 'include_recipe')
        end
      end
    end
  end
end
