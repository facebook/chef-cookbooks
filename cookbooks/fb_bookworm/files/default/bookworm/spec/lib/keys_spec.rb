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

describe 'Bookworm::BOOKWORM_KEYS' do
  let(:keys) { Bookworm::BOOKWORM_KEYS }

  it 'is frozen' do
    expect(keys).to be_frozen
  end

  it 'contains expected key types' do
    expected_keys = %w{
      cookbook role metadatarb metadatajson recipe recipejson
      attribute library resource provider cookbookrspec
    }
    expect(keys.keys).to match_array(expected_keys)
  end

  describe 'default values' do
    it 'sets default plural as key + s' do
      expect(keys['recipe']['plural']).to eq('recipes')
      expect(keys['role']['plural']).to eq('roles')
      expect(keys['attribute']['plural']).to eq('attributes')
    end

    it 'allows custom plural override' do
      expect(keys['library']['plural']).to eq('libraries')
    end

    it 'sets default source_dirs to cookbook_dirs' do
      expect(keys['recipe']['source_dirs']).to eq('cookbook_dirs')
      expect(keys['attribute']['source_dirs']).to eq('cookbook_dirs')
    end

    it 'allows custom source_dirs override' do
      expect(keys['role']['source_dirs']).to eq('role_dirs')
    end

    it 'sets default parser to RuboCop' do
      expect(keys['recipe']['parser']).to eq(Bookworm::Parsers::RuboCop)
      expect(keys['library']['parser']).to eq(Bookworm::Parsers::RuboCop)
    end

    it 'allows custom parser override' do
      expect(keys['metadatajson']['parser']).to eq(Bookworm::Parsers::JSON)
      expect(keys['recipejson']['parser']).to eq(Bookworm::Parsers::JSON)
    end

    it 'sets default glob_pattern based on plural' do
      expect(keys['recipe']['glob_pattern']).to eq('*/recipes/*.rb')
      expect(keys['attribute']['glob_pattern']).to eq('*/attributes/*.rb')
    end
  end

  describe 'cookbook metakey' do
    it 'is marked as a metakey' do
      expect(keys['cookbook']['metakey']).to eq(true)
    end

    it 'has dont_init_kb_key set' do
      expect(keys['cookbook']['dont_init_kb_key']).to eq(true)
    end
  end

  describe 'determine_cookbook_name' do
    it 'is true for recipe, attribute, library, resource, provider, cookbookrspec' do
      %w{recipe attribute library resource provider cookbookrspec}.each do |key|
        expect(keys[key]['determine_cookbook_name']).to eq(true)
      end
    end

    it 'is false for role' do
      expect(keys['role']['determine_cookbook_name']).to eq(false)
    end
  end

  describe 'path_name_regex' do
    it 'is set for all keys' do
      keys.each do |name, config|
        next if config['metakey']
        expect(config['path_name_regex']).not_to be_nil,
                                                 "Expected #{name} to have path_name_regex"
      end
    end
  end
end
