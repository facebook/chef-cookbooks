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
require_relative './spec_helper'

describe Bookworm::InferRules::IncludeRecipeOnly do
  it 'returns true for a single include_recipe call' do
    ast = generate_ast(<<~RUBY)
      include_recipe 'fb_foo::default'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(true)
  end

  it 'returns true for multiple include_recipe calls' do
    ast = generate_ast(<<~RUBY)
      include_recipe 'fb_foo::default'
      include_recipe 'fb_bar::setup'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(true)
  end

  it 'returns false for a recipe with resources' do
    ast = generate_ast(<<~RUBY)
      include_recipe 'fb_foo::default'
      file '/tmp/foo' do
        content 'hello'
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end

  it 'returns false for a recipe with variable assignments' do
    ast = generate_ast(<<~RUBY)
      foo = 'bar'
      include_recipe 'fb_foo::default'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end

  it 'returns false for a recipe with dynamic include_recipe' do
    ast = generate_ast(<<~'RUBY')
      include_recipe "fb_foo::#{something}"
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end

  it 'returns false for an empty recipe' do
    ast = RuboCop::AST::Node.new('bookworm_found_nil')
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end

  it 'returns false for a recipe with conditionals' do
    ast = generate_ast(<<~RUBY)
      if node['fb_foo']['enabled']
        include_recipe 'fb_foo::default'
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(false)
  end
end
