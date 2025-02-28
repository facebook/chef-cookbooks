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
  class InvertedBooleanLiteralCleanup < Base
    include RangeHelp
    extend AutoCorrector
    MSG = fb_msg('Inverted boolean literals should be cleaned up')

    def_node_matcher :inverted_boolean_literal?, <<-PATTERN
                                (send (${true false}) :!)
                                          PATTERN

    RESTRICT_ON_SEND = [:!].freeze
    def on_send(node)
      expression = inverted_boolean_literal?(node)
      return unless expression
      add_offense(node,
                  :severity => :refactor) do |corrector|
        corrector.replace(
          # Here we flip !true->false and !false->true
          node,
          # rubocop:disable Lint/BooleanSymbol
          (expression == :false).to_s,
          # rubocop:enable Lint/BooleanSymbol
        )
      end
    end
  end
end
