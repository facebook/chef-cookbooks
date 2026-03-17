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
  class AvoidPowershellWithoutGuard < Base

    MSG = fb_msg('Avoid using powershell_script without an "only_if" or "not_if" guard. ' +
                'To keep resources idempotent, add an "only_if" or "not_if" parameter ' +
                'and appropriate code')

    def_node_matcher :powershell_with_guard?, <<-PATTERN
          (block
            `(send nil? :powershell_script _ )
            (args)
            `(send nil? {:only_if :not_if} ... ))
          PATTERN

    RESTRICT_ON_SEND = [:powershell_script].freeze
    def on_send(node)
      return if powershell_with_guard?(node.parent)
      add_offense(node, :severity => :convention)
    end
  end
end
