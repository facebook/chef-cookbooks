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
#
require 'bookworm/knowledge_base'
require 'bookworm/infer_base_classes'

module Bookworm
  # The InferEngine class takes a KnowledgeBase object, and then runs the given
  # rules against the files within each bookworm key in the KnowledgeBase that
  # the rule uses.
  class InferEngine
    def initialize(knowledge_base, rules = [])
      @kb = knowledge_base

      rules.each do |rule|
        process_rule(rule)
      end
    end

    def process_rule(rule)
      klass = Bookworm::InferRules.const_get(rule)
      klass.keys.each do |key|
        @kb[key].each do |name, metadata|
          @kb[key][name][rule] = klass.new(metadata).output
        end
      end
    end

    def knowledge_base
      @kb
    end
  end
end
