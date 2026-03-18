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
  class AvoidIncludeAttribute < Base
    MSG = fb_msg('Do not use include_attribute')

    def_node_matcher :send_is_includeattribute?, <<-PATTERN
            (send nil? :include_attribute ...)
          PATTERN

    RESTRICT_ON_SEND = [:include_attribute].freeze
    def on_send(node)
      expression = send_is_includeattribute?(node)
      return unless expression

      add_offense(node, :severity => :error)
    end
  end
end
