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
require 'bookworm/parsers/json'

describe Bookworm::Parsers::JSON do
  describe '.parse' do
    it 'parses a simple JSON object' do
      result = described_class.parse('{"foo": "bar"}')
      expect(result).to eq({ 'foo' => 'bar' })
    end

    it 'parses a JSON array' do
      result = described_class.parse('[1, 2, 3]')
      expect(result).to eq([1, 2, 3])
    end

    it 'parses nested JSON' do
      result = described_class.parse('{"a": {"b": [1, 2]}}')
      expect(result).to eq({ 'a' => { 'b' => [1, 2] } })
    end

    it 'raises on invalid JSON' do
      expect { described_class.parse('{invalid}') }.to raise_error(::JSON::ParserError)
    end
  end

  describe '.parser_output_key' do
    it 'returns object' do
      expect(described_class.parser_output_key).to eq('object')
    end
  end
end
