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
  # node.override, node.set, node.normal, etc. cause attribute precedence
  # issues. Use node.default instead.
  class UseNodeDefault < Base
    MSG = fb_msg(
      'Please use node.default, other attribute levels break the FB model',
    )

    # def_node_matcher creates a function that matches AST patterns
    def_node_matcher :bad_node_method?, <<-PATTERN
            (send (send _ :node) {:override :set :normal :force_default :force_override :automatic})
          PATTERN

    RESTRICT_ON_SEND = [:override, :set, :normal, :force_default, :force_override, :automatic].freeze
    def on_send(node)
      expression = bad_node_method?(node)
      return unless expression

      add_offense(node, :severity => :error)
    end
  end
end
