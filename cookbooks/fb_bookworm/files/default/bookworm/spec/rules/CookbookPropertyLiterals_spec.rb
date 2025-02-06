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
require_relative './helper'

describe Bookworm::InferRules::CookbookPropertyLiterals do
  it 'returns empty array when no cookbook property' do
    ast = generate_ast(<<~RUBY)
      cookbook_file 'just_a_plain_old_resource'
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([])
  end
  it 'returns cookbook that file resource uses (no begin block)' do
    ast = generate_ast(<<~RUBY)
      cookbook_file 'just_a_plain_old_resource' do
        cookbook 'foo'
      end
    RUBY
    rule = described_class.new({
                                 'cookbook' => 'fake_cookbook',
      'ast' => ast,
                               })
    expect(rule.output).to eq(['foo'])
  end
  it 'returns cookbook that file resource uses (with begin block)' do
    ast = generate_ast(<<~RUBY)
      cookbook_file 'just_a_plain_old_resource' do
        ignore 'this'
        cookbook 'foo'
        also 'ignore'
      end
    RUBY
    rule = described_class.new({
                                 'cookbook' => 'fake_cookbook',
      'ast' => ast,
                               })
    expect(rule.output).to eq(['foo'])
  end
  it 'returns multiple cookbooks used by known resource' do
    ast = generate_ast(<<~RUBY)
      file 'just_a_plain_old_resource'

      cookbook_file 'from_foo' do
        cookbook 'foo'
      end

      template 'from_bar' do
        cookbook 'bar'
      end

      remote_directory 'from_baz' do
        cookbook 'baz'
      end
    RUBY
    rule = described_class.new({
                                 'cookbook' => 'fake_cookbook',
      'ast' => ast,
                               })
    expect(rule.output).to eq(['bar', 'baz', 'foo']) # results are sorted
  end
end
