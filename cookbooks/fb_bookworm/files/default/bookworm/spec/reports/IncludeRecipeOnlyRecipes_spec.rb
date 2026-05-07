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

describe Bookworm::Reports::IncludeRecipeOnlyRecipes do
  let(:mock_kb) do
    MockKnowledgeBase.new(
      :recipes => recipes,
    )
  end
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no recipes' do
    let(:recipes) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end
  end

  describe 'with mixed recipes' do
    let(:recipes) do
      {
        'fb_init::default' => {
          'cookbook' => 'fb_init',
          'IncludeRecipeOnly' => true,
        },
        'fb_apache::default' => {
          'cookbook' => 'fb_apache',
          'IncludeRecipeOnly' => false,
        },
        'fb_motd::default' => {
          'cookbook' => 'fb_motd',
          'IncludeRecipeOnly' => true,
        },
      }
    end

    it 'returns only include_recipe-only recipes sorted' do
      expect(report.to_a).to eq(['fb_init::default', 'fb_motd::default'])
    end

    it 'excludes recipes with other content' do
      expect(report.to_a).not_to include('fb_apache::default')
    end
  end
end
