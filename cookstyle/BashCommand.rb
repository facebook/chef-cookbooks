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
  # This cop checks for usage of bash resources with command instead of code
  class BashCommand < Base
    extend AutoCorrector
    MSG = fb_msg("Do not use the 'command' property on a bash resource, use the 'code' property instead.")

    def_node_matcher :bash_command?, <<-PATTERN
      (block
        (send nil? :bash _ )
        (args)
        `$(send nil? :command _ )
      )
    PATTERN

    RESTRICT_ON_SEND = [:command].freeze

    def on_block(node)
      command = bash_command?(node)
      return unless command

      add_offense(command,
                  :severity => :warning) do |corrector|
        corrector.replace(command, "code #{command.arguments.map(&:source).first}")
      end
    end
  end
end
