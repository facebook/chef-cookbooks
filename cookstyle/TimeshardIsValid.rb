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

module RuboCop::Cop::Chef::Meta
  class TimeshardIsValid < Base
    MSG_S = fb_msg('node.in_timeshard? start is invalid')
    MSG_D = fb_msg('node.in_timeshard? duration is invalid')

    def_node_matcher :node_in_timeshard?, <<-PATTERN
            (send (send nil? :node) :in_timeshard? (str $_) (str $_))
          PATTERN

    RESTRICT_ON_SEND = [:in_timeshard?].freeze

    def on_send(node)
      expression = node_in_timeshard?(node)
      return unless expression
      return unless expression[0].is_a?(String) && expression[1].is_a?(String)

      # If either of these exception, then we've got an offense
      begin
        Time.parse(expression[0]).tv_sec
      rescue ArgumentError
        add_offense(node,
                    :message => MSG_S,
                    :severity => :refactor)
      end
      begin
        parse_timeshard_duration(expression[1])
      rescue RuntimeError
        add_offense(node,
                    :message => MSG_D,
                    :severity => :refactor)
      end
    end
  end
end
