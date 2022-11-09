# Copyright (c) 2022-present, Meta, Inc.
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
  class KnowledgeBase

    def initialize(opts)
      BOOKWORM_KEYS.each do |k, v|
        instance_variable_set("@#{k}", {})
        init_keys(k, opts[k] || []) unless v['dont_init_kb_key']
      end
    end

    # Create pluralized getter methods
    BOOKWORM_KEYS.each do |k, v|
      define_method(v['plural'].to_sym) do
        instance_variable_get("@#{k}")
      end
    end

    def add_metadata(key, name, rule, metadata)
      instance_variable_get("@#{key}")[name][rule] = metadata
    end

    def init_keys(key, files)
      path_name_regex = BOOKWORM_KEYS[key]['path_name_regex']
      iv = instance_variable_get("@#{key}")
      if BOOKWORM_KEYS[key]['determine_cookbook_name']
        files.each do |path, ast|
          m = path.match(%r{/?([\w-]+)/#{path_name_regex}})
          cookbook_name = m[1]
          file_name = m[2]
          @cookbook[cookbook_name] ||= {}
          iv["#{cookbook_name}::#{file_name}"] =
            { 'path' => path, 'cookbook' => cookbook_name, 'ast' => ast }
        end
      else
        files.each do |path, ast|
          m = path.match(/#{path_name_regex}/)

          file_name = m[1]
          iv[file_name] = { 'path' => path, 'ast' => ast }
        end
      end
    end
  end
end
