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

# A caveat with this linter is that it cannot determine `if false`
# because some deprecated thing was converted to `false`, versus you
# wanting to disable something temporarily with `if false`. It's like in
# addition to nil and false we need some other way of saying "false,
# because I'll forget about this reverted diff in 2 months" ;-)
# In the event you really want to keep that boolean literal condition
# add a comment with `rubocop:disable Chef/Meta/ConditionalBooleanLiteralCleanup`

module RuboCop::Cop::Chef::Meta
  class ConditionalBooleanLiteralCleanup < Base
    include RangeHelp
    extend AutoCorrector
    MSG = fb_msg('Boolean literals as conditionals should be cleaned up')

    # This class only fires on true/false boolean literals, as firing on
    # every single if-type node would be expensive. However, you'll
    # quickly notice most operations are on the `if` node of the AST,
    # hence the `ifnode` variable.
    #
    # To keep the logic readable, we'll be using the `if` helper methods
    # from rubocop-ast wherever possible
    # https://github.com/rubocop/rubocop-ast/blob/master/lib/rubocop/ast/node/if_node.rb

    def on_true(node)
      return unless node&.parent&.if_type?
      return unless node.sibling_index == 0 # Checks `true` is the conditional, not the value

      ifnode = node.parent

      add_offense(node,
                  :severity => :refactor) do |corrector|
        if ifnode.elsif?
          replace_elsif_true(corrector, ifnode)
        elsif ifnode.unless?
          if ifnode.branches.count == 1
            replace_unless_true(corrector, ifnode)
          else
            replace_unless_true_else(corrector, ifnode)
          end
        else
          replace_if_true(corrector, ifnode)
        end
      end
    end

    def on_false(node)
      return unless node&.parent&.if_type?
      return unless node.sibling_index == 0 # Checks `false` is the conditional, not the value

      ifnode = node.parent

      add_offense(node,
                  :severity => :refactor) do |corrector|
        if ifnode.if? || ifnode.ternary?
          # The false is in the if branch
          if ifnode.branches.count == 1
            replace_if_false(corrector, ifnode)
          elsif ifnode.elsif_conditional?
            replace_if_false_elsif(corrector, ifnode)
          else
            replace_if_false_else(corrector, ifnode)
          end
        elsif ifnode.unless?
          replace_unless_false(corrector, ifnode)
        elsif ifnode.branches.count == 1
          # The false is in the elsif branch
          replace_elsif_false(corrector, ifnode)
        elsif ifnode.elsif_conditional?
          replace_elsif_false_elsif(corrector, ifnode)
        else
          replace_elsif_false_else(corrector, ifnode)
        end
      end
    end

    private

    # if foo
    #   untouched_case
    # elsif true <- fires here
    #   contents
    # else
    #   will_be_removed
    # end
    def replace_elsif_true(corrector, ifnode)
      str = "else\n"
      str << ' ' * ifnode.if_branch.loc.column
      str << ifnode.if_branch.source
      corrector.replace(ifnode, str)
    end

    # # if/else
    # if true <- fires here
    #   contents
    # else
    #   will_be_removed
    # end
    #
    # # if/elsif/else
    # if true <- fires here
    #   contents
    # elsif whatever
    #   will_be_removed
    # else
    #   will_be_removed
    # end
    #
    # # ternary
    # foo = true ? contents : will_be_removed
    def replace_if_true(corrector, ifnode)
      corrector.replace(ifnode, ifnode.if_branch.source)
    end
    alias replace_unless_false replace_if_true

    # if false <-- you are here
    #   will_be_removed
    # end
    def replace_if_false(corrector, ifnode)
      corrector.replace(ifnode, '')
    end
    alias replace_unless_true replace_if_false

    # if foo
    #   untouched_case
    # elsif false <-- you are here
    #   will_be_removed
    # end
    def replace_elsif_false(corrector, ifnode)
      range = range_between(
        ifnode.parent.else_branch.loc.expression.begin_pos,
        ifnode.parent.loc.end.begin_pos,
      )
      corrector.replace(range, '')
    end

    # foo = false ? will_be_removed : contents
    #
    # if false
    #   will_be_removed
    # else
    #   untouched_case
    # end
    def replace_if_false_else(corrector, ifnode)
      corrector.replace(ifnode, ifnode.else_branch.source)
    end
    alias replace_unless_true_else replace_if_false_else

    # if false
    #    puts "this should go"
    # elsif var
    #    puts "this should be the new if"
    # elsif bar
    #    puts "this should remain"
    # else
    #    puts "this should remain, too"
    # end
    #
    # if false
    #    puts "this should go"
    # elsif var
    #    puts "this should be the new if"
    # else
    #    puts "this should remain, too"
    # end
    def replace_if_false_elsif(corrector, ifnode)
      range = range_between(
        ifnode.condition.loc.expression.begin_pos,
        ifnode.else_branch.condition.loc.expression.begin_pos,
      )
      corrector.replace(range, '')
    end

    # if foo
    #    puts "this should stay"
    # elsif false
    #    puts "this should go"
    # else
    #    puts "this should remain"
    # end
    def replace_elsif_false_else(corrector, ifnode)
      range = range_between(
        ifnode.loc.expression.begin_pos,
        ifnode.loc.else.begin_pos,
      )
      corrector.replace(range, '')
    end

    # if foo
    #   puts "this should stay"
    # elsif false
    #   puts "this should go"
    # elsif var
    #   puts "this should remain"
    # else
    #   puts "this should remain, too"
    # end
    def replace_elsif_false_elsif(corrector, ifnode)
      range = range_between(
        ifnode.loc.expression.begin_pos,
        ifnode.else_branch.loc.expression.begin_pos,
      )
      corrector.replace(range, '')
    end
  end
end
