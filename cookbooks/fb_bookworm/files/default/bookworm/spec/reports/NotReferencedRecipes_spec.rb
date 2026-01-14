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

describe Bookworm::Reports::NotReferencedRecipes do
  let(:mock_kb) { MockKnowledgeBase.new(:roles => roles, :recipes => recipes, :recipejsons => recipejsons) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no recipes' do
    let(:roles) { {} }
    let(:recipes) { {} }
    let(:recipejsons) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with some unreferenced recipes' do
    let(:roles) do
      {
        'base_role' => {
          'RoleRunListRecipes' => ['fb_init::default'],
        },
      }
    end
    let(:recipes) do
      {
        'fb_init::default' => {
          'IncludeRecipeLiterals' => ['fb_helpers::default'],
        },
        'fb_helpers::default' => {
          'IncludeRecipeLiterals' => [],
        },
        'fb_unused::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end
    let(:recipejsons) do
      {
        'fb_json_unused::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end

    it 'returns sorted unreferenced recipes' do
      expect(report.to_a).to eq([
        'fb_json_unused::default',
        'fb_unused::default',
      ])
    end

    it 'output returns sorted unreferenced recipes' do
      expect(report.output).to eq([
        'fb_json_unused::default',
        'fb_unused::default',
      ])
    end
  end

  describe 'with JSON recipes referencing other recipes' do
    let(:roles) { {} }
    let(:recipes) do
      {
        'fb_target::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end
    let(:recipejsons) do
      {
        'fb_json::default' => {
          'IncludeRecipeLiterals' => ['fb_target::default'],
        },
      }
    end

    it 'marks recipes referenced by JSON recipes as referenced' do
      expect(report.to_a).to eq(['fb_json::default'])
    end
  end
end
