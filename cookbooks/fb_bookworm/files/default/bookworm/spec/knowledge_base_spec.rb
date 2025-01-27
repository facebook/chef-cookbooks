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
end
