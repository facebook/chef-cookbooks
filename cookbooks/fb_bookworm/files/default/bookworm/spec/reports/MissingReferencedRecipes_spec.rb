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

describe Bookworm::Reports::MissingReferencedRecipes do
  let(:mock_kb) { MockKnowledgeBase.new(:roles => roles, :recipes => recipes, :recipejsons => recipejsons) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no roles or recipes' do
    let(:roles) { {} }
    let(:recipes) { {} }
    let(:recipejsons) { {} }

    it 'returns empty hash with roles and recipes keys' do
      expect(report.to_h).to eq({ 'roles' => {}, 'recipes' => {} })
    end

    it 'to_plain indicates no missing recipes' do
      output = report.to_plain
      expect(output).to include('No missing recipes coming from the roles files')
      expect(output).to include('No missing recipes coming from the recipe files')
    end
  end

  describe 'with references to missing recipes' do
    let(:roles) do
      {
        'base_role' => {
          'RoleRunListRecipes' => ['fb_init::default', 'fb_missing::default'],
        },
      }
    end
    let(:recipes) do
      {
        'fb_init::default' => {
          'IncludeRecipeLiterals' => ['fb_helpers::default', 'fb_nonexistent::setup'],
        },
        'fb_helpers::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end
    let(:recipejsons) { {} }

    it 'returns missing recipes from roles' do
      result = report.to_h
      expect(result['roles']['base_role']).to eq(['fb_missing::default'])
    end

    it 'returns missing recipes from recipes' do
      result = report.to_h
      expect(result['recipes']['fb_init::default']).to eq(['fb_nonexistent::setup'])
    end

    it 'to_plain includes missing recipe information' do
      output = report.to_plain
      expect(output).to include('Roles:')
      expect(output).to include('base_role')
      expect(output).to include('fb_missing::default')
      expect(output).to include('Recipes:')
      expect(output).to include('fb_init::default')
      expect(output).to include('fb_nonexistent::setup')
    end
  end

  describe 'with JSON recipes referencing missing recipes' do
    let(:roles) { {} }
    let(:recipes) do
      {
        'fb_existing::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end
    let(:recipejsons) do
      {
        'fb_json::default' => {
          'IncludeRecipeLiterals' => ['fb_existing::default', 'fb_missing_from_json::setup'],
        },
      }
    end

    it 'returns missing recipes from JSON recipes' do
      result = report.to_h
      expect(result['recipes']['fb_json::default']).to eq(['fb_missing_from_json::setup'])
    end
  end
end
