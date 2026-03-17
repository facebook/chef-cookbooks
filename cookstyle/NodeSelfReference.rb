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
  class NodeSelfReference < Base
    extend AutoCorrector
    MSG = fb_msg('No need to have multiple node.node calls')

    def_node_matcher :bad_node_method?, <<-PATTERN
            (send (send nil? :node) :node)
          PATTERN

    RESTRICT_ON_SEND = [:node].freeze
    def on_send(node)
      return unless bad_node_method?(node)

      add_offense(node, :severity => :warning) do |corrector|
        corrector.replace(node, 'node')
      end
    end
  end
end
