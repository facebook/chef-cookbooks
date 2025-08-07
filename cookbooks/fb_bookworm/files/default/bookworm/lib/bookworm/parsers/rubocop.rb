# frozen_string_literal: true

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
#

require 'rubocop'
require 'parser/current'

module Bookworm
  class Parsers
    class RuboCop < ::Bookworm::KeyParserBase
      # In order to keep rules from barfing on a nil value (when no AST is
      # generated at all from eg. an empty source code file), we supply a
      # single node called bookworm_found_nil. It's a magic value that is
      # 'unique enough' for our purposes
      EMPTY_RUBOCOP_AST = ::RuboCop::AST::Node.new('bookworm_found_nil').freeze
      def self.parse(str)
        ::RuboCop::ProcessedSource.new(str, RUBY_VERSION.to_f)&.ast ||
          EMPTY_RUBOCOP_AST
      end

      def self.parser_output_key
        'ast'
      end
    end
  end

  class Crawler
    # TODO: Fix references to use Bookworm::Parsers::RuboCop::EMPTY_RUBOCOP_AST
    EMPTY_RUBOCOP_AST = ::Bookworm::Parsers::RuboCop::EMPTY_RUBOCOP_AST
  end
end
