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
require 'rubocop'
require 'parser/current'
# require 'ripper'

# TODO(dcrosby) move AST generation to a rule? This would allow multiple AST
# parsers (ie ripper), which would be beneficial on heavy-duty rules It would
# also remove overhead if only using string search/regexes in a rule (not a lot
# of great use cases, but they exist)

module Bookworm
  class Crawler
    attr_reader :processed_files

    def initialize(config, keys: [])
      @config = config

      # TODO(dcrosby) add messages to verbose mode
      to_crawl = {}
      keys.each do |k|
        v = BOOKWORM_KEYS[k]
        to_crawl[k] = @config.source_dirs[v['source_dirs']].
                      map { |d| Dir.glob("#{d}/#{v['glob_pattern']}") }.flatten
      end
      @processed_files = {}
      to_crawl.each do |key, files|
        instance_variable_set("@#{key}_intake_queue", files)
        instance_variable_set("@#{key}_processed_files", {})
        @processed_files[key] = process_paths(key)
      end
    end

    private

    def process_paths(key)
      queue = instance_variable_get("@#{key}_intake_queue")
      processed_files = {}
      until queue.empty?
        path = queue.pop
        processed_files[path] = generate_ast(File.read(path))
      end
      processed_files
    end

    # Direct parser gem use is several seconds faster than using Rubocop
    def generate_parser_ast(code)
      Parser::CurrentRuby.parse(code)
    end

    # def generate_ripper_ast(code)
    #   Ripper.sexp(code)[1]
    # end

    # In order to keep rules from barfing on a nil value (when no AST is
    # generated at all from eg. an empty source code file), we supply a
    # single node called bookworm_found_nil. It's a magic value that is
    # 'unique enough' for our purposes
    EMPTY_RUBOCOP_AST = ::RuboCop::AST::Node.new('bookworm_found_nil').freeze
    def generate_rubocop_ast(code)
      ::RuboCop::ProcessedSource.new(code, RUBY_VERSION.to_f)&.ast ||
        EMPTY_RUBOCOP_AST
    end

    alias generate_ast generate_rubocop_ast
  end
end
