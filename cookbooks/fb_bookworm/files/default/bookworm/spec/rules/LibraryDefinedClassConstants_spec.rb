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
require_relative './helper'

describe Bookworm::InferRules::LibraryDefinedClassConstants do
  it 'returns empty array when no class defined' do
    ast = generate_ast(<<~RUBY)
      true
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([])
  end
  it 'captures the top-level class name' do
    ast = generate_ast(<<~RUBY)
      class Foo ; end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([:Foo])
  end
  it 'captures class name inside module' do
    ast = generate_ast(<<~RUBY)
      module Bar
        class Foo ; end
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([:Foo])
  end
  it 'captures nested class names' do
    ast = generate_ast(<<~RUBY)
      class Bar
        class Foo ; end
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([:Bar, :Foo])
  end
end
