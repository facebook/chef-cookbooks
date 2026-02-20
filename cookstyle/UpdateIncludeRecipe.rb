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
  class UpdateIncludeRecipe < Base
    extend AutoCorrector # used for autocorrection
    MSG = fb_msg('This cookbook\'s call site should be changed to the new cookbook name')

    def_node_matcher :include_recipe_string_literal, '(send nil? :include_recipe (str $_))'

    # Returns either a replacement cookbook name, or nil
    def cookbook_replacement(name)
      changes = cop_config['CookbookNameChanges'] || {}
      changes[name]
    end

    RESTRICT_ON_SEND = [:include_recipe].freeze
    def on_send(node)
      include_recipe_str = include_recipe_string_literal(node)
      return unless include_recipe_str

      return if include_recipe_str.start_with?('::') # Local recipes start with ::, which are easy enough to fix by hand
      cookbook, recipe = include_recipe_str.split('::')
      if (rep = cookbook_replacement(cookbook))
        add_offense(node, :severity => :warning) do |corrector|
          replacement = recipe ? "'#{rep}::#{recipe}'" : "'#{rep}'"
          corrector.replace(node.child_nodes[0], replacement)
        end
      end
    end
  end
end
