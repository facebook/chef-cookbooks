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
  class WindowsTaskAbsolutePaths < Base
    MSG = fb_msg('Use absolute executable paths for commands to avoid' +
    ' path abuse.')
    REGEX = %r{
      (?:[a-z]+:|\\\\[a-z0-9_.$-]+\\[a-z0-9_.$-]+|%\w+%)
      (?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*
    }x.freeze

    def_node_matcher :windows_task_resource?, <<-PATTERN
            (block (send nil? :windows_task _) ...)
          PATTERN

    def_node_matcher :get_send_command, <<-PATTERN
            `(send nil? :command (str $_))
          PATTERN

    def_node_matcher :delete_action?, <<-PATTERN
            `(sym {:delete | :disable})
          PATTERN

    def_node_matcher :command_with_interpolated_params, <<-PATTERN
            `(send nil? :command (dstr (str $_) ...))
          PATTERN

    def absolute_command?(command)
      exe = command.to_str.split(' ')[0].downcase
      # Regex to support drive letters, UNC, and relative special paths
      # (e.g. %windir%) plus a file path.
      # https://rubular.com/r/IVYssMSjCR9u9n
      # Pathname.absolute? does not work well for Windows paths.
      return REGEX.match?(exe)
    end

    include RuboCop::Chef::CookbookHelpers
    def on_block(node)
      return unless windows_task_resource?(node) # early return
      match_property_in_resource?(:windows_task,
                                  'action', node) do |property|
        # We can ignore delete's and disable.
        return if property.child_nodes.any? { |k| delete_action?(k) }
      end
      match_property_in_resource?(:windows_task,
                                  'command', node) do |property|
        if (cmd = get_send_command(property))
          unless absolute_command?(cmd)
            add_offense(property,
                        :severity => :warning)
          end
        elsif (cmd = command_with_interpolated_params(property))
          unless absolute_command?(cmd)
            add_offense(property,
                        :severity => :warning)
          end
        end
      end
    end
  end
end
