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
  # This cop checks for usage of `node.default[...]` in a read context.
  # While syntactically correct, it's semantically wrong, causing
  # auto-vivification (ie it will never return nil, it will return the
  # stored value *or* create an empty hash). This means that using a
  # node.default attribute in a logic statement will always return true
  # unless it has explicitly been set to false.
  #
  # Deliberately relying on auto-vivification in a read operation to
  # create an empty hash is footgun behaviour, don't cause a SEV to save
  # one line ;-)
  #
  # or_asgn nodes are flagged, as checking node.default for nil will
  # trigger the auto-vivification. You can run chef-shell to see this
  # play out:
  # chef (14.15.6)> node['foo']
  #  => nil
  # chef (14.15.6)> node.default['foo'] ||= 'blerb'
  #  => {}
  class NodeDefaultWritesOnly < Base
    extend AutoCorrector
    MSG = fb_msg('node.default should be used for writes only, ' +
                 'use node instead')

    def_node_matcher :node_default?, <<-PATTERN
            (send
              (send nil? :node)
              :default)
          PATTERN

    # NOTE - list of methods pulled by running `chef-shell`, running
    # `[Hash, Mash, Array].map {|x| x.instance_methods }.sort.uniq`
    # and then manually adding anything that mutates to this list.
    # It'll need to be updated with new Ruby versions, but the minor
    # inconvenience is worth the protection this linter provides
    MUTATING_METHODS = [
      :+,
      :-,
      :<<,
      :[]=,
      :append,
      :prepend,
      :clear,
      :collect!,
      :concat,
      :delete,
      :delete_if!,
      :insert,
      :merge!,
      :push,
      :unshift,
      :update,
    ].freeze

    def parent_mutating_method?(node)
      return false unless node.parent?
      if node.parent.send_type?
        if node.parent.method?(:[])
          # Attributes are nested
          return parent_mutating_method?(node.parent)
        elsif MUTATING_METHODS.include?(node.parent.method_name)
          # Bingo, it's a mutating (write) operation
          return true
        else
          # Didn't see any mutating methods. This can potentially
          # false-positive if a new method has been added to Hash/Mash
          # since the last Chef update.
          return false
        end
      elsif node.parent.op_asgn_type?
        # Operation assignment, eg += and -=
        return true
      else
        return false
      end
    end

    # A special case where code is technically reliant on auto-vivification
    # to create the hash, but as we're doing an or-assignment the behaviour
    # is the same.
    #
    # example:  node.default['foo']['bar'] ||= {}
    def parent_autovivification_hash_assignment?(node)
      return false unless node.parent?
      if node.parent.send_type?
        if node.parent.method?(:[])
          # Attributes are nested
          return parent_autovivification_hash_assignment?(node.parent)
        end
      elsif node.parent.or_asgn_type?
        return node.parent.expression.hash_type? && node.parent.expression.empty?
      else
        return false
      end
    end

    def parent_or_assignment?(node)
      return false unless node.parent?
      if node.parent.send_type?
        if node.parent.method?(:[])
          return parent_or_assignment?(node.parent)
        end
      elsif node.parent.or_asgn_type?
        return true
      else
        return false
      end
    end

    RESTRICT_ON_SEND = [:default].freeze
    def on_send(node)
      # Due to the complexity of the task, we'll first search for the use
      # of node.default (it's *much* cheaper than checking for the
      # individual read/write operations) After that, we'll check for a
      # parent node that indicates a write operation. In the absence of
      # that, we can assume that the attribute use is read-only, which is
      # a warning.
      return unless node_default? node
      return if parent_mutating_method?(node)
      return if parent_autovivification_hash_assignment?(node)
      add_offense(node, :severity => :warning) do |corrector|
        corrector.replace(node, 'node') unless parent_or_assignment?(node)
      end
    end
  end
end
