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

describe Bookworm::InferRules::IncludeRecipeLiterals do
  it 'returns empty array when no include_recipe' do
    ast = generate_ast(<<~RUBY)
      file 'just_a_plain_old_resource'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([])
  end
  it 'returns qualified recipe name with :: prefix sugar' do
    ast = generate_ast(<<~RUBY)
      include_recipe '::fake_recipe'
    RUBY
    rule = described_class.new({
                                 'cookbook' => 'fake_cookbook',
      'ast' => ast,
                               })
    expect(rule.output).to eq(['fake_cookbook::fake_recipe'])
  end
  it 'returns qualified recipe name with implied default recipe' do
    ast = generate_ast(<<~RUBY)
      include_recipe 'fake_cookbook'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(['fake_cookbook::default'])
  end
  it 'returns qualified recipe name with qualified recipe name' do
    ast = generate_ast(<<~RUBY)
      include_recipe 'fake_cookbook::fake_recipe'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(['fake_cookbook::fake_recipe'])
  end
  it 'handles multiple include_recipe calls' do
    ast = generate_ast(<<~RUBY)
      file 'stub' # <- some code to test AST recursion
      include_recipe 'fake_cookbook::foo'
      include_recipe 'fake_cookbook::bar'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    # Note - output is sorted
    expect(rule.output).to eq(['fake_cookbook::bar', 'fake_cookbook::foo'])
  end
end
