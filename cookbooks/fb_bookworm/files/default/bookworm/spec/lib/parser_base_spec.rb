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
require_relative '../spec_helper'
require 'bookworm/parser_base'

describe Bookworm::KeyParserBase do
  describe '.parse' do
    it 'raises an error when called directly' do
      expect { described_class.parse('anything') }.to raise_error(
        RuntimeError, 'parse method required to inherit KeyParserBase class'
      )
    end
  end
end
