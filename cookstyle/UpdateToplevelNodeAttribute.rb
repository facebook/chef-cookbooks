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
  class UpdateToplevelNodeAttribute < Base
    extend AutoCorrector # used for autocorrection

    MSG = fb_msg('Use the new top-level node attribute')

    # Returns either a replacement key name, or nil
    def key_replacement(name)
      changes = cop_config['ToplevelKeyChanges'] || {}
      changes[name]
    end

    def_node_matcher :node_write?, <<-PATTERN
            (send
              (send nil? :node)
              :default)
          PATTERN

    def_node_matcher :node_toplevel_key, <<-PATTERN
          (send
            (send
              (send nil? :node) _) { :[]= :[] }
            (str $_)
          _ ?)
          PATTERN

    def_node_matcher :migrated_code, <<-PATTERN
          (send
            (send
              (send nil? :node) :default) :[]=
            (str _)
            (send ...))
          PATTERN

    # Check if this is a chained assignment like:
    # node.default['fb_new']... = node.default['fb_old']... = {}
    # We need to walk up to find the outermost assignment and check if
    # its value is also a node.default assignment chain
    def migrated_assignment?(top_node)
      return false unless top_node&.send_type?

      # The value being assigned (last child) should also be a node.default assignment
      value_node = top_node.children.last
      return false unless value_node&.send_type?

      # Check if the value chain leads to node.default
      current = value_node
      while current&.send_type?
        receiver = current.children[0]
        if receiver&.send_type? && node_write?(receiver)
          return true
        end
        current = receiver
      end
      false
    end

    RESTRICT_ON_SEND = [:node].freeze
    def on_send(node)
      return unless node.parent? && node.parent.parent? && node_write?(node.parent)

      tlk = node_toplevel_key(node.parent.parent)
      return unless tlk && (tlk_replacement = key_replacement(tlk))

      tmp_top_node = node.parent
      top_node = nil
      loop do
        if tmp_top_node&.parent&.send_type?
          tmp_top_node = tmp_top_node.parent
        else
          top_node = tmp_top_node
          break
        end
      end

      # To prevent an infinite rewrite loop, we need to detect that the *new
      # line* is not written on the following line
      return if migrated_assignment?(top_node)

      new_write = top_node.source.gsub(tlk, tlk_replacement)
      new_write.gsub!(/\]\s*=.*/, '] = ')

      # If we got a match, rewrite to the new method
      add_offense(top_node, :severity => :warning) do |corrector|
        corrector.insert_before(node.parent.parent, new_write)
      end
    end
  end
end
