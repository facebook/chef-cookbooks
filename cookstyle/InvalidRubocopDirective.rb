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
  # `[r]ubocop:ignore` is not a valid RuboCop directive. The correct
  # directive is `rubocop:disable`. Using `[r]ubocop:ignore` silently
  # does nothing, so the cop you intended to suppress still fires.
  # (comments tweaked here so cop doesn't flag itself)
  class InvalidRubocopDirective < Base
    include RangeHelp
    extend AutoCorrector

    MSG = fb_msg(
      '`rubocop:ignore` is not a valid directive. ' \
      'Use `rubocop:disable` instead.',
    )

    INVALID_DIRECTIVE = /rubocop:ignore\b/.freeze

    def on_new_investigation
      processed_source.comments.each do |comment|
        next unless comment.text.match?(INVALID_DIRECTIVE)

        match = comment.text.match(INVALID_DIRECTIVE)
        start = comment.loc.expression.begin_pos +
                comment.text.index(match[0])
        range = Parser::Source::Range.new(
          processed_source.buffer,
          start,
          start + match[0].length,
        )

        add_offense(range, :severity => :warning) do |corrector|
          corrector.replace(range, 'rubocop:disable')
        end
      end
    end
  end
end
