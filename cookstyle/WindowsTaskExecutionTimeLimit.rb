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
  class WindowsTaskExecutionTimeLimit < Base

    # Windows scheduled tasks default to a 72-hour execution time limit,
    # which may cause long-running tasks to be terminated unexpectedly.
    # Always set execution_time_limit explicitly.
    MSG = fb_msg('Missing execution_time_limit for scheduled task')

    def_node_matcher :windows_task_resource?, <<-PATTERN
            (block (send nil? :windows_task _) ...)
          PATTERN
    def_node_matcher :delete_action?, <<-PATTERN
          `(sym {:delete | :disable})
        PATTERN

    include RuboCop::Chef::CookbookHelpers
    def on_block(node)
      return unless windows_task_resource?(node)
      match_property_in_resource?(:windows_task, 'action', node) do |property|
        # We can ignore delete's and disable.
        return if property.child_nodes.any? { |k| delete_action?(k) }
      end

      match_property_in_resource?(:windows_task, 'execution_time_limit', node) do |_property|
        return
      end
      add_offense(node, :severity => :warning)
    end
  end
end
