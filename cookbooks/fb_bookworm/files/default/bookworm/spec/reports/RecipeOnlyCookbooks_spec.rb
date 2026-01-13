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

describe Bookworm::Reports::RecipeOnlyCookbooks do
  let(:mock_kb) do
    MockKnowledgeBase.new(
      :cookbooks => cookbooks,
      :attributes => attributes,
      :libraries => libraries,
      :resources => resources,
      :providers => providers,
    )
  end
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no cookbooks' do
    let(:cookbooks) { {} }
    let(:attributes) { {} }
    let(:libraries) { {} }
    let(:resources) { {} }
    let(:providers) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with mixed cookbooks' do
    let(:cookbooks) do
      {
        'fb_apache' => {},
        'fb_helpers' => {},
        'fb_init' => {},
        'fb_sysctl' => {},
      }
    end
    let(:attributes) do
      {
        'fb_apache::default' => { 'cookbook' => 'fb_apache' },
      }
    end
    let(:libraries) do
      {
        'fb_helpers::helpers' => { 'cookbook' => 'fb_helpers' },
      }
    end
    let(:resources) do
      {
        'fb_sysctl::sysctl' => { 'cookbook' => 'fb_sysctl' },
      }
    end
    let(:providers) { {} }

    it 'returns cookbooks with only recipes' do
      result = report.to_a
      expect(result).to eq(['fb_init'])
    end

    it 'excludes cookbooks with attributes' do
      expect(report.to_a).not_to include('fb_apache')
    end

    it 'excludes cookbooks with libraries' do
      expect(report.to_a).not_to include('fb_helpers')
    end

    it 'excludes cookbooks with resources' do
      expect(report.to_a).not_to include('fb_sysctl')
    end
  end
end
