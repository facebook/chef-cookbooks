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

describe Bookworm::Reports::NoParsedRuby do
  let(:mock_kb) do
    MockKnowledgeBase.new(
      :recipes => recipes,
      :attributes => attributes,
      :libraries => libraries,
      :resources => resources,
      :providers => providers,
      :metadatarbs => metadatarbs,
      :roles => roles,
    )
  end
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with empty collections' do
    let(:recipes) { {} }
    let(:attributes) { {} }
    let(:libraries) { {} }
    let(:resources) { {} }
    let(:providers) { {} }
    let(:metadatarbs) { {} }
    let(:roles) { {} }

    it 'returns hash with empty arrays for each key type' do
      result = report.to_h
      expect(result['recipes']).to eq([])
      expect(result['attributes']).to eq([])
      expect(result['libraries']).to eq([])
      expect(result['resources']).to eq([])
      expect(result['providers']).to eq([])
      expect(result['metadatarbs']).to eq([])
      expect(result['roles']).to eq([])
    end

    it 'to_plain indicates no non-AST files' do
      output = report.to_plain
      expect(output).to include('No non-AST')
    end
  end

  describe 'with files having NoParsedRuby flag' do
    let(:recipes) do
      {
        'fb_helpers::default' => { 'NoParsedRuby' => false },
        'fb_init::default' => { 'NoParsedRuby' => true },
      }
    end
    let(:attributes) do
      {
        'fb_helpers::default' => { 'NoParsedRuby' => true },
      }
    end
    let(:libraries) { {} }
    let(:resources) { {} }
    let(:providers) { {} }
    let(:metadatarbs) { {} }
    let(:roles) { {} }

    it 'returns files with NoParsedRuby flag' do
      result = report.to_h
      expect(result['recipes']).to eq(['fb_init::default'])
      expect(result['attributes']).to eq(['fb_helpers::default'])
    end

    it 'to_plain includes flagged files' do
      output = report.to_plain
      expect(output).to include('fb_init::default')
    end
  end
end
