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
require_relative './spec_helper'

describe Bookworm::InferRules::IncludeRecipeDynamic do
  it 'returns false on no AST' do
    ast = generate_ast(<<~RUBY)
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end
  it 'returns false where no include_recipe found' do
    ast = generate_ast(<<~RUBY)
      file 'just_a_plain_old_resource'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end
  it 'returns false where no dynamic include_recipe found' do
    ast = generate_ast(<<~RUBY)
      include_recipe '::fake_recipe'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end
  it 'returns true where include_recipe with variable found' do
    ast = generate_ast(<<~RUBY)
    var = '::fake_recipe'
    include_recipe var
  RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(true)
  end
  it 'returns true where include_recipe with interpolated string found' do
    ast = generate_ast(<<~RUBY)
    include_recipe "\#{cookbook_name}::fake_recipe"
  RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(true)
  end
end
