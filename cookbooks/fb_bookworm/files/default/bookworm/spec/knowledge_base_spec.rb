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
require_relative 'spec_helper'
require 'bookworm/keys'
require 'bookworm/knowledge_base'

describe Bookworm::KnowledgeBase do
  it 'holds all yer roles' do
    kb = Bookworm::KnowledgeBase.new({
                                       'role' => [['foo.rb', '(ast)']],
                                     })
    expect(kb.roles).to eq({ 'foo' => { 'path' => 'foo.rb', 'ast'=> '(ast)' } })
  end
  it 'holds all yer metadatarbs' do
    kb = Bookworm::KnowledgeBase.new({
                                       'metadatarb' => [['thing/metadata.rb', '(ast)']],
                                     })
    expect(kb.cookbooks).to eq({ 'thing' => {} })
    expect(kb.metadatarbs).to eq({ 'thing::metadata.rb' => {
                                   'path' => 'thing/metadata.rb',
      'cookbook' => 'thing',
      'ast' => '(ast)',
                                 } })
  end
  it 'holds all yer recipes' do
    kb = Bookworm::KnowledgeBase.new({
                                       'recipe'=> [['thing/recipes/default.rb', '(ast)']],
                                     })
    expect(kb.recipes).to eq({ 'thing::default' => {
                               'path' => 'thing/recipes/default.rb',
      'cookbook' => 'thing',
      'ast' => '(ast)',
                             } })
  end
  it 'holds all yer attributes' do
    kb = Bookworm::KnowledgeBase.new(
      {
        'attribute' => [['thing/attributes/default.rb', '(ast)']],
      },
    )
    expect(kb.attributes).to eq({ 'thing::default' => {
                                  'path' => 'thing/attributes/default.rb',
      'cookbook' => 'thing',
      'ast' => '(ast)',
                                } })
  end
  it 'holds all yer libraries' do
    kb = Bookworm::KnowledgeBase.new(
      { 'library' => [['thing/libraries/default.rb', '(ast)']] },
    )
    expect(kb.libraries).to eq({ 'thing::default' => {
                                 'path' => 'thing/libraries/default.rb',
      'cookbook' => 'thing',
      'ast' => '(ast)',
                               } })
  end

  it 'holds all yer resources' do
    kb = Bookworm::KnowledgeBase.new(
      { 'resource' => [['mycookbook/resources/my_resource.rb', '(ast)']] },
    )
    expect(kb.resources).to eq({ 'mycookbook::my_resource' => {
                                 'path' => 'mycookbook/resources/my_resource.rb',
      'cookbook' => 'mycookbook',
      'ast' => '(ast)',
                               } })
  end

  it 'holds all yer providers' do
    kb = Bookworm::KnowledgeBase.new(
      { 'provider' => [['mycookbook/providers/my_provider.rb', '(ast)']] },
    )
    expect(kb.providers).to eq({ 'mycookbook::my_provider' => {
                                 'path' => 'mycookbook/providers/my_provider.rb',
      'cookbook' => 'mycookbook',
      'ast' => '(ast)',
                               } })
  end

  it 'holds all yer recipejsons' do
    kb = Bookworm::KnowledgeBase.new(
      { 'recipejson' => [['mycookbook/recipes/data.json', { 'key' => 'value' }]] },
    )
    expect(kb.recipejsons).to eq({ 'mycookbook::data' => {
                                   'path' => 'mycookbook/recipes/data.json',
      'cookbook' => 'mycookbook',
      'object' => { 'key' => 'value' },
                                 } })
  end

  it 'holds all yer metadatajsons' do
    kb = Bookworm::KnowledgeBase.new(
      { 'metadatajson' => [['mycookbook/metadata.json', { 'name' => 'mycookbook' }]] },
    )
    expect(kb.metadatajsons).to eq({ 'mycookbook::metadata.json' => {
                                     'path' => 'mycookbook/metadata.json',
      'cookbook' => 'mycookbook',
      'object' => { 'name' => 'mycookbook' },
                                   } })
  end

  it 'handles empty input' do
    kb = Bookworm::KnowledgeBase.new({})
    expect(kb.recipes).to eq({})
    expect(kb.roles).to eq({})
    expect(kb.attributes).to eq({})
  end

  it 'handles multiple files of the same type' do
    kb = Bookworm::KnowledgeBase.new({
                                       'recipe' => [
                                         ['cookbook_a/recipes/default.rb', '(ast1)'],
                                         ['cookbook_a/recipes/other.rb', '(ast2)'],
                                         ['cookbook_b/recipes/default.rb', '(ast3)'],
                                       ],
                                     })
    expect(kb.recipes.keys).to match_array([
      'cookbook_a::default', 'cookbook_a::other', 'cookbook_b::default'
    ])
  end

  describe '[] accessor' do
    it 'returns the hash for a key' do
      kb = Bookworm::KnowledgeBase.new({
                                         'recipe' => [['thing/recipes/default.rb', '(ast)']],
                                       })
      expect(kb['recipe']).to eq(kb.recipes)
    end
  end

  describe '[]= accessor' do
    it 'allows setting values' do
      kb = Bookworm::KnowledgeBase.new({})
      kb['recipe']['test::default'] = { 'custom' => 'data' }
      expect(kb.recipes['test::default']).to eq({ 'custom' => 'data' })
    end
  end
end
