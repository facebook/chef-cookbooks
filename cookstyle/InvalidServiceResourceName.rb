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
  class InvalidServiceResourceName < Base
    # If a service resource doesn't have an explicit service_name property,
    # it's inferred from the name property. This can lead to latent bugs where
    # the service shellout calls don't work.
    MSG = fb_msg('This is an invalid service name for the name property. Use service_name property for service name.')

    def_node_matcher :service_resource, <<-PATTERN
      (block (send nil? :service (str $_) ...) ...)
    PATTERN

    def_node_search :has_service_name_method, <<-PATTERN
      (send nil? :service_name _)
    PATTERN

    RESTRICT_ON_SEND = [:service].freeze
    def on_send(node)
      return unless node.parent?
      name_property = service_resource(node.parent)

      # return if it's nil (ie can't determine name statically) or valid
      return if name_property.nil? || name_property.match?(/^[a-zA-Z0-9.@\\:_-]+$/)

      # the block has a service_name method, so name isn't inferred
      return if has_service_name_method(node.parent).any?

      add_offense(node, :severity => :warning)
    end
  end
end
