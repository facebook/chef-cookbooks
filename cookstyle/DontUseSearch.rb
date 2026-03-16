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
  # Search is a mechanism to search through all the data on the server -
  # typically to search for nodes that match some criteria. This has
  # scalability issues at large fleet sizes and the data one would
  # typically search on will not be present on the Chef server.
  class DontUseSearch < Base
    MSG = fb_msg(
      "Don't use Chef search - it has scalability issues and the data " +
      'you need will not be present on the server.',
    )

    def_node_matcher :send_is_search?, <<-PATTERN
            (send nil? :search ...)
          PATTERN

    RESTRICT_ON_SEND = [:search].freeze
    def on_send(node)
      expression = send_is_search?(node)
      return unless expression

      add_offense(node, :severity => :error)
    end
  end
end
