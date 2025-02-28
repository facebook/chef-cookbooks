# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates
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
require 'rubocop'

# TODO(dcrosby) This will eventually be upstreamed as a fix to the
# boolean literal cops in RuboCop, but for now this addresses some
# cleanup that other Cookstyle cops do (which is why this is a Cookstyle
# cop, and not in our RuboCop-only config).

module RuboCop::Cop::Chef::Meta
  # This lint removes boolean literals (true/false keywords) where we can guarantee it:
  # A) does *not* change the logic flow
  # B) does *not* change the returning value
  # C) does *not* change any side effects
  #
  # This removes booleans that are on the left-hand side (LHS) of a logical operation
  #   true && foo  => foo
  #   false || foo => foo
  #
  # We do not auto-correct RHS booleans, since this can create side-effects.
  # An example:
  #   if File.write('test', 'sideeffect') && false
  #     puts 'never runs because of `&& false`'
  #   end
  #   File.read('test') # Runtime failure if 'test' file isn't written!
  #
  # TODO: Handle semantic (and/or) operators? Currently avoiding them to avoid precedence issues.
  class CompoundBooleanLiteralCleanup < Base
    include RangeHelp
    extend AutoCorrector
    MSG = fb_msg('Boolean literals with logic operators should be cleaned up')

    def node_is_lhs_operand?(node)
      if (node.parent.and_type? || node.parent.or_type?) &&
          node.sibling_index == 0 &&
          node.parent.logical_operator?
        node.parent.type
      end
    end

    def on_true(node)
      if node.parent?
        if (op = node_is_lhs_operand?(node))
          if op == :and
            # redundant boolean
            remove_lhs(node)
          else
            # short circuit
            remove_rhs(node)
          end
        end
      end
    end

    def on_false(node)
      if node.parent?
        if (op = node_is_lhs_operand?(node))
          if op == :and
            # short circuit
            remove_rhs(node)
          else
            # redundant boolean
            remove_lhs(node)
          end
        end
      end
    end

    def remove_rhs(node)
      add_offense(node,
                  :severity => :refactor) do |corrector|
        corrector.replace(
          node.parent,
          node.parent.lhs.source,
        )
      end
    end

    def remove_lhs(node)
      add_offense(node,
                  :severity => :refactor) do |corrector|
        corrector.replace(
          node.parent,
          node.parent.rhs.source,
        )
      end
    end
  end
end
