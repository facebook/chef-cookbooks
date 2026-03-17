# Copyright (c) 2023-present, Meta Platforms, Inc. and affiliates
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
  # Autocorrect foo:bar to foo::bar in include_recipe
  class BadIncludeRecipe < Base
    extend AutoCorrector
    MSG = fb_msg('include_recipe needs two colons, not a single colon, to separate cookbooks')

    def_node_matcher :bad_include_recipe_method?, <<-PATTERN
            (send nil? :include_recipe (str $_))
          PATTERN

    RESTRICT_ON_SEND = [:include_recipe].freeze

    def on_send(node)
      recipe = bad_include_recipe_method?(node)

      # Return unless we have a single colon match
      return unless recipe&.match?(/^[a-zA-Z0-9_]*:[a-zA-Z0-9_]+$/)
      add_offense(node,
                  :severity => :refactor) do |corrector|
        # Switch to single quotes *shrug*
        corrector.replace(node.children[2], "'#{recipe.gsub(':', '::')}'")
      end
    end
  end
end
