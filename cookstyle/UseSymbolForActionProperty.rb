# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates.
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
  class UseSymbolForActionProperty < Base
    extend AutoCorrector
    include RuboCop::Chef::CookbookHelpers

    MSG = fb_msg(
      'Use a symbol, not a string, for a resource action (e.g. ' +
      '`action :install`) to avoid string allocations and keep actions uniform.',
    )

    RESTRICT_ON_SEND = [:action].freeze
    def on_send(node)
      block = node.each_ancestor(:block).first
      return unless block && looks_like_resource?(block)
      node.arguments.each do |arg|
        if arg.str_type?
          register(arg)
        elsif arg.array_type?
          arg.each_child_node(:str) { |element| register(element) }
        end
      end
    end

    private

    def register(str_node)
      add_offense(str_node, :severity => :refactor) do |corrector|
        corrector.replace(str_node, str_node.value.to_sym.inspect)
      end
    end
  end
end
