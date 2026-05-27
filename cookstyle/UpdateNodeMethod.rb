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
  class UpdateNodeMethod < Base
    extend AutoCorrector

    MSG = fb_msg('This node method should be updated to its replacement')
    MSG_LVAR = fb_msg(
      'This node method should be updated to its replacement ' +
      '(assuming this is a Chef::Node object)',
    )

    def changes
      cop_config['Changes'] || {}
    end

    def on_send(node)
      return unless node.receiver
      lvar = node.receiver.lvar_type? && node.receiver.source == 'node'
      return unless node.self_receiver? ||
        (node.receiver.send_type? && node.receiver.method?(:node)) ||
        lvar
      replacement_method = changes[node.method_name.to_s]
      return unless replacement_method

      msg = lvar ? MSG_LVAR : MSG
      add_offense(node, :message => msg, :severity => :warning) do |corrector|
        corrector.replace(
          node.loc.selector,
          replacement_method,
        )
      end
    end
  end
end
