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
require 'bookworm/keys'
require 'bookworm/knowledge_base'
require 'bookworm/infer_engine'

describe Bookworm::InferEngine do
  before do
    # Create a simple test rule
    Bookworm::InferRules.const_set(:TestEngineRule, Class.new(Bookworm::InferRule))
    Bookworm::InferRules::TestEngineRule.class_eval do
      keys ['recipe']

      def to_a
        ['extracted_value']
      end
    end
  end

  after do
    Bookworm::InferRules.send(:remove_const, :TestEngineRule)
  end

  describe '#initialize' do
    it 'stores the knowledge base' do
      kb = Bookworm::KnowledgeBase.new({})
      engine = described_class.new(kb, [])
      expect(engine.knowledge_base).to eq(kb)
    end

    it 'processes rules against the knowledge base' do
      kb = Bookworm::KnowledgeBase.new({
                                         'recipe' => [['cookbook/recipes/default.rb', '(ast)']],
                                       })
      described_class.new(kb, ['TestEngineRule'])

      expect(kb.recipes['cookbook::default']['TestEngineRule']).to eq(['extracted_value'])
    end
  end

  describe '#process_rule' do
    it 'runs rule against all files matching the rule keys' do
      kb = Bookworm::KnowledgeBase.new({
                                         'recipe' => [
                                           ['cookbook_a/recipes/default.rb', '(ast)'],
                                           ['cookbook_b/recipes/foo.rb', '(ast)'],
                                         ],
                                       })
      engine = described_class.new(kb, [])
      engine.process_rule('TestEngineRule')

      expect(kb.recipes['cookbook_a::default']['TestEngineRule']).to eq(['extracted_value'])
      expect(kb.recipes['cookbook_b::foo']['TestEngineRule']).to eq(['extracted_value'])
    end

    it 'only processes keys the rule applies to' do
      # Create a rule that only applies to attributes
      Bookworm::InferRules.const_set(:AttributeOnlyRule, Class.new(Bookworm::InferRule))
      Bookworm::InferRules::AttributeOnlyRule.class_eval do
        keys ['attribute']
        def to_a
          ['attr_value']
        end
      end

      kb = Bookworm::KnowledgeBase.new({
                                         'recipe' => [['cookbook/recipes/default.rb', '(ast)']],
                                         'attribute' => [['cookbook/attributes/default.rb', '(ast)']],
                                       })
      engine = described_class.new(kb, [])
      engine.process_rule('AttributeOnlyRule')

      expect(kb.recipes['cookbook::default']['AttributeOnlyRule']).to be_nil
      expect(kb.attributes['cookbook::default']['AttributeOnlyRule']).to eq(['attr_value'])

      Bookworm::InferRules.send(:remove_const, :AttributeOnlyRule)
    end
  end

  describe '#knowledge_base' do
    it 'returns the knowledge base' do
      kb = Bookworm::KnowledgeBase.new({})
      engine = described_class.new(kb, [])
      expect(engine.knowledge_base).to be(kb)
    end
  end
end
