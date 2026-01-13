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

describe Bookworm::Reports::DynamicRecipeInclusion do
  let(:mock_kb) { MockKnowledgeBase.new(:recipes => recipes) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no recipes' do
    let(:recipes) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with recipes having dynamic inclusion' do
    let(:recipes) do
      {
        'fb_helpers::default' => {
          'IncludeRecipeDynamic' => false,
        },
        'fb_init::default' => {
          'IncludeRecipeDynamic' => true,
        },
        'fb_apache::setup' => {
          'IncludeRecipeDynamic' => true,
        },
        'fb_nginx::default' => {
          'IncludeRecipeDynamic' => nil,
        },
      }
    end

    it 'returns sorted recipes with dynamic inclusion' do
      expect(report.to_a).to eq([
        'fb_apache::setup',
        'fb_init::default',
      ])
    end

    it 'output returns sorted recipes with dynamic inclusion' do
      expect(report.output).to eq([
        'fb_apache::setup',
        'fb_init::default',
      ])
    end
  end
end
