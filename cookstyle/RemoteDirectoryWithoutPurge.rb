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
  class RemoteDirectoryWithoutPurge < Base
    MSG = fb_msg(
      'Using remote_directory without purging leaves files behind on the filesystem ' +
      'which can cause hard-to-debug issues if the entire directory is consumed elsewhere',
    )

    # Example:
    # remote_directory 'fb-something' do
    # end
    def_node_matcher :is_remote_directory?, <<-PATTERN
            (block
              (send nil? :remote_directory _)
              (args)
              _
            )
          PATTERN

    # Example:
    # remote_directory 'fb-something' do
    #   ...
    #   purge true
    # end
    def_node_matcher :has_purge_as_true?, <<-PATTERN
            (block
              (send nil? :remote_directory _)
              (args)
              `(send nil? :purge (true) )
              )
          PATTERN

    def on_block(node)
      return unless is_remote_directory?(node)
      return if has_purge_as_true?(node)
      add_offense(node, :severity => :warning)
    end
  end
end
