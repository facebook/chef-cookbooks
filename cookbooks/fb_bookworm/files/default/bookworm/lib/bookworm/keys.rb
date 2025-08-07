# frozen_string_literal: true

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

require 'bookworm/parsers/builtin_parsers'

module Bookworm
  # These keys are how we generalize and generate a lot of code within Bookworm
  #
  # VALUES
  # metakey: A metakey isn't crawled, but is useful as a place to store information
  # plural: The pluralized form of the key - typically used in method creation
  # source_dirs: Specify which array of source directories to crawl
  # glob_pattern: Specify the glob pattern for which files to crawl in source directories
  # dont_init_kb_key: Don't initialize the keys on knowledge base creation
  # determine_cookbook_name: Determines the cookbook name from the given path
  # path_name_regex: A regex with a capture to determine the prettified name of the file
  #
  # TODO: handle cookbook root alias files like cookbook/attributes.rb
  # https://github.com/chef/chef/blob/d22fa4cdc46c58e450198427b86c4de4ed9a90e3/docs/dev/design_documents/cookbook_root_aliases.md?plain=1#L25-L28
  BOOKWORM_KEYS = {
    'cookbook' => {
      'metakey' => true,
      'dont_init_kb_key' => true,
    },
    'role' => {
      'source_dirs' => 'role_dirs',
      'glob_pattern' => '*.rb',
      'path_name_regex' => '([\w-]+)\.rb',
    },
    'metadatarb' => {
      'glob_pattern' => '*/metadata.rb',
      'determine_cookbook_name' => true,
      'path_name_regex' => '(metadata\.rb)',
    },
    'recipe' => {
      'determine_cookbook_name' => true,
      'path_name_regex' => 'recipes/(.*)\.rb',
    },
    'recipejson' => {
      'determine_cookbook_name' => true,
      'glob_pattern' => '*/recipes/*.json',
      'path_name_regex' => 'recipes/(.*)\.json',
      'parser' => ::Bookworm::Parsers::JSON,
    },
    'attribute' => {
      'determine_cookbook_name' => true,
      'path_name_regex' => 'attributes/(.*)\.rb',
    },
    'library' => {
      'plural' => 'libraries', # <-- the troublemaker that prompted keys first ;-)
      'determine_cookbook_name' => true,
      'path_name_regex' => 'libraries\/(.*)\.rb',
    },
    'resource' => {
      'determine_cookbook_name' => true,
      'path_name_regex' => 'resources/(.*)\.rb',
    },
    'provider' => {
      'determine_cookbook_name' => true,
      'path_name_regex' => 'providers/(.*)\.rb',
    },
  }.freeze

  # Set defaults
  BOOKWORM_KEYS.each do |k, v|
    BOOKWORM_KEYS[k]['determine_cookbook_name'] ||= false
    BOOKWORM_KEYS[k]['plural'] ||= "#{k}s"
    BOOKWORM_KEYS[k]['parser'] ||= ::Bookworm::Parsers::RuboCop
    BOOKWORM_KEYS[k]['source_dirs'] ||= 'cookbook_dirs'
    BOOKWORM_KEYS[k]['glob_pattern'] ||= "*/#{v['plural']}/*.rb"
  end

  BOOKWORM_KEYS.freeze
end
