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
require 'bookworm/exceptions'
require 'bookworm/infer_base_classes'

describe Bookworm::InferRule do
  describe 'class attributes' do
    it 'has default empty description on subclass' do
      test_class = Class.new(described_class)
      expect(test_class.description).to be_nil
    end

    it 'has default nil keys on subclass' do
      test_class = Class.new(described_class)
      expect(test_class.keys).to be_nil
    end

    it 'allows setting description' do
      test_class = Class.new(described_class)
      test_class.description 'Test description'
      expect(test_class.description).to eq('Test description')
    end

    it 'allows setting keys' do
      test_class = Class.new(described_class)
      test_class.keys ['recipe', 'resource']
      expect(test_class.keys).to eq(['recipe', 'resource'])
    end
  end

  describe '#initialize' do
    it 'stores metadata' do
      rule = described_class.new({ 'ast' => 'test_ast' })
      expect(rule.instance_variable_get(:@metadata)).to eq({ 'ast' => 'test_ast' })
    end

    it 'calls output on initialization' do
      test_class = Class.new(described_class) do
        def output
          @output_called = true
          super
        end
      end
      rule = test_class.new({})
      expect(rule.instance_variable_get(:@output_called)).to eq(true)
    end
  end

  describe '#to_a' do
    it 'returns empty array by default' do
      rule = described_class.new({})
      expect(rule.to_a).to eq([])
    end
  end

  describe '#to_h' do
    it 'returns empty hash by default' do
      rule = described_class.new({})
      expect(rule.to_h).to eq({})
    end
  end

  describe '#default_output' do
    it 'returns :to_a by default' do
      rule = described_class.new({})
      expect(rule.default_output).to eq(:to_a)
    end
  end

  describe '#output' do
    it 'calls the method returned by default_output' do
      rule = described_class.new({})
      expect(rule.output).to eq([])
    end

    it 'can be overridden via default_output' do
      test_class = Class.new(described_class) do
        def default_output
          :to_h
        end
      end
      rule = test_class.new({})
      expect(rule.output).to eq({})
    end
  end
end

describe 'Bookworm.load_rule_class' do
  after do
    # Clean up any test rules we create
    if Bookworm::InferRules.const_defined?(:TestRule)
      Bookworm::InferRules.send(:remove_const, :TestRule)
    end
  end

  it 'creates a new class under Bookworm::InferRules' do
    rule_content = <<~RUBY
      description 'A test rule'
      keys ['recipe']
    RUBY
    allow(File).to receive(:read).with('/fake/dir/TestRule.rb').and_return(rule_content)

    Bookworm.load_rule_class(:TestRule, :dir => '/fake/dir')

    expect(Bookworm::InferRules.const_defined?(:TestRule)).to eq(true)
    expect(Bookworm::InferRules::TestRule.superclass).to eq(Bookworm::InferRule)
    expect(Bookworm::InferRules::TestRule.description).to eq('A test rule')
    expect(Bookworm::InferRules::TestRule.keys).to eq(['recipe'])
  end

  it 'raises ClassLoadError on failure' do
    allow(File).to receive(:read).and_raise(Errno::ENOENT)

    expect do
      Bookworm.load_rule_class(:NonexistentRule, :dir => '/fake/dir')
    end.to raise_error(Bookworm::ClassLoadError)
  end
end

describe 'Bookworm.load_rules_dir' do
  after do
    # Clean up any test rules we create
    [:RuleOne, :RuleTwo].each do |name|
      if Bookworm::InferRules.const_defined?(name)
        Bookworm::InferRules.send(:remove_const, name)
      end
    end
  end

  it 'loads all .rb files from a directory' do
    allow(Dir).to receive(:glob).with('/fake/rules/*.rb').and_return(
      ['/fake/rules/RuleOne.rb', '/fake/rules/RuleTwo.rb'],
    )
    allow(File).to receive(:read).with('/fake/rules/RuleOne.rb').and_return(
      "description 'Rule one'",
    )
    allow(File).to receive(:read).with('/fake/rules/RuleTwo.rb').and_return(
      "description 'Rule two'",
    )

    Bookworm.load_rules_dir('/fake/rules')

    expect(Bookworm::InferRules::RuleOne.description).to eq('Rule one')
    expect(Bookworm::InferRules::RuleTwo.description).to eq('Rule two')
  end
end

describe Bookworm::InferRules do
  it 'is a module' do
    expect(Bookworm::InferRules).to be_a(Module)
  end
end
