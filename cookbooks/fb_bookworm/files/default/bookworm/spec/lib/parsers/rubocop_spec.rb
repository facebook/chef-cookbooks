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
require_relative '../../spec_helper'
require 'bookworm/parser_base'
require 'bookworm/parsers/rubocop'

describe Bookworm::Parsers::RuboCop do
  describe '.parse' do
    it 'returns an AST node for valid Ruby code' do
      ast = described_class.parse('foo = 1')
      expect(ast).to be_a(RuboCop::AST::Node)
      expect(ast.type).to eq(:lvasgn)
    end

    it 'returns EMPTY_RUBOCOP_AST for empty string' do
      ast = described_class.parse('')
      expect(ast).to eq(described_class::EMPTY_RUBOCOP_AST)
    end

    it 'returns EMPTY_RUBOCOP_AST for whitespace-only string' do
      ast = described_class.parse("   \n\n  ")
      expect(ast).to eq(described_class::EMPTY_RUBOCOP_AST)
    end

    it 'parses method calls' do
      ast = described_class.parse("include_recipe 'foo::bar'")
      expect(ast.type).to eq(:send)
    end
  end

  describe '.parser_output_key' do
    it 'returns ast' do
      expect(described_class.parser_output_key).to eq('ast')
    end
  end

  describe '::EMPTY_RUBOCOP_AST' do
    it 'is a frozen RuboCop AST node' do
      expect(described_class::EMPTY_RUBOCOP_AST).to be_a(RuboCop::AST::Node)
      expect(described_class::EMPTY_RUBOCOP_AST).to be_frozen
    end

    it 'has type bookworm_found_nil' do
      expect(described_class::EMPTY_RUBOCOP_AST.type).to eq(:bookworm_found_nil)
    end
  end
end
