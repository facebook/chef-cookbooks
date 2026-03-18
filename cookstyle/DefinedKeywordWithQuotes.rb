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
  class DefinedKeywordWithQuotes < Base
    MSG = fb_msg(
      '`defined?` with a quoted string always returns "expression". ' +
      'Use `defined?(SomeConstant)` without quotes.',
    )

    def on_defined?(node)
      child = node.children.first
      return unless child&.type == :str || child&.type == :dstr

      add_offense(node, :severity => :warning)
    end
  end
end
