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

describe Bookworm::Reports::AllReferencedRecipes do
  let(:mock_kb) { MockKnowledgeBase.new(:roles => roles, :recipes => recipes) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no roles or recipes' do
    let(:roles) { {} }
    let(:recipes) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with roles and recipes referencing recipes' do
    let(:roles) do
      {
        'base_role' => {
          'RoleRunListRecipes' => ['fb_init::default', 'fb_helpers::default'],
        },
      }
    end
    let(:recipes) do
      {
        'fb_init::default' => {
          'IncludeRecipeLiterals' => ['fb_sysctl::default', 'fb_helpers::default'],
        },
        'fb_helpers::default' => {
          'IncludeRecipeLiterals' => [],
        },
      }
    end

    it 'returns sorted unique recipes from roles and recipes' do
      expect(report.to_a).to eq([
        'fb_helpers::default',
        'fb_init::default',
        'fb_sysctl::default',
      ])
    end

    it 'output returns sorted unique recipes' do
      expect(report.output).to eq([
        'fb_helpers::default',
        'fb_init::default',
        'fb_sysctl::default',
      ])
    end
  end
end
