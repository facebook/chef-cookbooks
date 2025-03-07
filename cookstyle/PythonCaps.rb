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
  class PythonCaps < Base
    extend AutoCorrector
    MSG = fb_msg('It looks like you are using Python syntax in Ruby, ' +
    'change to true or false')

    # Check if True or False are included
    def_node_matcher :casgn_caps_true_false?, <<-PATTERN
            (casgn nil? {:False :True} _?)
            PATTERN

    def_node_matcher :const_caps_true_false?, <<-PATTERN
            (const nil? {:False :True} _?)
            PATTERN

    def on_casgn(node)
      expression = casgn_caps_true_false?(node)
      return unless expression
      add_offense(node, :severity => :warning)
    end

    def on_const(node)
      expression = const_caps_true_false?(node)
      return unless expression
      add_offense(node,
                  :severity => :warning) do |corrector|
        corrector.replace(node, node.short_name.to_s.downcase)
      end
    end
  end
end
