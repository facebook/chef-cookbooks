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
  class OrderedDependancies < Base
    extend AutoCorrector

    MSG = fb_msg('Dependencies should be in alphabetical order.')

    # Grab the dependant name
    def_node_matcher :get_dependant, <<~PATTERN
      (send nil? :depends (str $_))
    PATTERN

    # This needs to be done at this level vs on_send because we need to be
    # able to offer an autocorrect that doesn't lose items when correcting
    def on_new_investigation
      src = processed_source

      node = src.ast
      # only keep `depends ...`
      actual_dependencies = node.children.filter_map do |child|
        r = get_dependant(child)
        r unless r.nil?
      end
      expected_sorted = actual_dependencies.sort

      return if actual_dependencies == expected_sorted # skip if it's already sorted

      # Grab everything except lines with depends
      sans_depends = src.raw_source.each_line.reject do |x|
        x.start_with?('depends')
      end

      # Add the depends in order at the end
      sans_depends += expected_sorted.map { |d| "depends '#{d}'\n" }

      add_offense(node, :severity => :refactor) do |c|
        c.replace(processed_source.buffer.source_range, sans_depends.join)
      end
    end
  end
end
