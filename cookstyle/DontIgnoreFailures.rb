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
  class DontIgnoreFailures < Base
    MSG = fb_msg('Avoid using ignore_failure whenever possible, ' +
      'it makes it harder to reason about system state during a run.')

    RESTRICT_ON_SEND = [:ignore_failure].freeze
    def on_send(node)
      unless node.arguments? && node.arguments[0].false_type?
        add_offense(node, :severity => :convention)
      end
    end
  end
end
