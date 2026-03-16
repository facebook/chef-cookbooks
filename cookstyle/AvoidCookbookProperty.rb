# Copyright (c) 2022-present, Meta Platforms, Inc. and affiliates
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
  class AvoidCookbookProperty < Base
    include RuboCop::Chef::CookbookHelpers

    MSG = fb_msg('Avoid referencing resources from another cookbook')

    def_node_matcher :resource_block, <<-PATTERN
            (block (send nil? ${:cookbook_file :template :remote_directory} _) ...)
          PATTERN

    def on_block(node)
      resource_type = resource_block(node)
      return unless resource_type
      match_property_in_resource?(resource_type, 'cookbook', node) do
        add_offense(node, :severity => :warning)
        return # there could be multiple uses of cookbook, but one offense fire in a block is enough
      end
    end
  end
end
