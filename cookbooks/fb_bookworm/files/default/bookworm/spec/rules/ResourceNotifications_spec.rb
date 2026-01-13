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
require_relative './spec_helper'

describe Bookworm::InferRules::ResourceNotifications do
  it 'captures nothing when there is no subscribes' do
    ast = generate_ast(<<~RUBY)
      file "foo" do
        action :touch
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([])
  end

  it 'captures when there is a subscribes property with three parameters' do
    ast = generate_ast(<<~RUBY)
      file "foo" do
        action :touch
        subscribes :run, 'service[foo]', :immediately
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([[:subscribes, :run, ['service[foo]'], :immediately]])
  end

  it 'captures when there is a subscribes property with two parameters (ie implied :delayed)' do
    ast = generate_ast(<<~RUBY)
      file "foo" do
        action :touch
        subscribes :run, 'service[foo]'
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([[:subscribes, :run, ['service[foo]'], :delayed]])
  end

  it 'captures when there is a subscribes property with multiple resources (array)' do
    ast = generate_ast(<<~RUBY)
      file "foo" do
        action :touch
        subscribes :run, 'service[foo]', :immediately
        subscribes :run, 'service[bar]', :immediately
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([
      [:subscribes, :run, ['service[foo]'], :immediately],
      [:subscribes, :run, ['service[bar]'], :immediately],
    ])
  end

  it 'captures when there is a subscribes property with multiple resources (array)' do
    ast = generate_ast(<<~RUBY)
      file "foo" do
        action :touch
        subscribes :run, ['service[foo]', 'service[bar]'], :immediately
      end
    RUBY
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq([[:subscribes, :run, ['service[foo]', 'service[bar]'], :immediately]])
  end
end
