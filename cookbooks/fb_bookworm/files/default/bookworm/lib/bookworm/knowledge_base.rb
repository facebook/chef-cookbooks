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
require 'pathname'
module Bookworm
  module KnowledgeBaseBackends
    # The SimpleHash backend stores the KnowledgeBase information as ... a
    # simple hash. No concurrency guarantees, caching, etc. Each bookworm run
    # will run all the rules, every time.
    module SimpleHash
      def init_hooks
        @kb_internal_hash = {}
      end

      def [](key)
        @kb_internal_hash[key]
      end

      def []=(key, value)
        @kb_internal_hash[key] = value
      end
    end
  end

  # The KnowledgeBase is a backend-agnostic way of storing and querying
  # information that's generated about the files via InferRules.
  #
  # We provide indirect access to the information stored by the
  # knowledge base, so that we'll soon be able to leverage different
  # backends (for concurrent writes, caching rule output across runs, etc).
  class KnowledgeBase
    def initialize(opts)
      extend Bookworm::KnowledgeBaseBackends::SimpleHash

      init_hooks

      # TODO: Only initialize keys required by rules
      BOOKWORM_KEYS.each do |k, v|
        unless v['dont_init_kb_key']
          if v['determine_cookbook_name']
            init_key_with_cookbook_name(k, opts[k] || [])
          else
            init_key(k, opts[k] || [])
          end
        end
        create_pluralized_getter(k)
      end
    end

    def backend_missing
      fail 'Need to specify a backend for KnowledgeBase class'
    end

    def [](_key)
      backend_missing
    end

    def []=(_key, _value)
      backend_missing
    end

    def init_hooks
      # This is optional for KnowledgeBaseBackends
    end

    private

    # This creates a method based off the (pluralized) Bookworm key.
    # Syntactical sugar that can make some rules/reports easier to read.
    def create_pluralized_getter(key)
      define_singleton_method(BOOKWORM_KEYS[key]['plural'].to_sym) do
        self[key]
      end
    end

    def init_key(key, files)
      self[key] = {}
      path_name_regex = BOOKWORM_KEYS[key]['path_name_regex']
      files.each do |path, ast|
        m = path.match(/#{path_name_regex}/)
        file_name = m[1]
        self[key][file_name] = { 'path' => path, 'ast' => ast }
      end
    end

    # The difference between this method and init_key is that it:
    # 1. initializes cookbook metakey if it doesn't already exist
    # 2. instead of using the filename for file key, uses COOKBOOK::FILENAME
    # where FILENAME has the '.rb' suffix stripped (making it similar to the
    # include_recipe calling conventions in Chef
    def init_key_with_cookbook_name(key, files)
      self[key] = {}
      self['cookbook'] ||= {}
      path_name_regex = BOOKWORM_KEYS[key]['path_name_regex']
      files.each do |path, ast|
        m = path.match(%r{/?([\w-]+)/#{path_name_regex}})
        cookbook_name = m[1]
        file_name = m[2]
        self['cookbook'][cookbook_name] ||= {}
        self[key]["#{cookbook_name}::#{file_name}"] =
          { 'path' => path, 'cookbook' => cookbook_name, 'ast' => ast }
      end
    end
  end
end
