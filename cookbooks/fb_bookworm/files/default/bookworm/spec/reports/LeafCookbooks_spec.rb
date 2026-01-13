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

describe Bookworm::Reports::LeafCookbooks do
  let(:mock_kb) do
    MockKnowledgeBase.new(:metadatarbs => metadatarbs, :metadatajsons => metadatajsons, :cookbooks => cookbooks)
  end
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no cookbooks' do
    let(:metadatarbs) { {} }
    let(:metadatajsons) { {} }
    let(:cookbooks) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with cookbooks having dependencies' do
    let(:metadatarbs) do
      {
        'fb_apache::metadata.rb' => {
          'ExplicitMetadataDepends' => ['fb_helpers', 'fb_sysctl'],
        },
        'fb_helpers::metadata.rb' => {
          'ExplicitMetadataDepends' => ['fb_init'],
        },
        'fb_init::metadata.rb' => {
          'ExplicitMetadataDepends' => [],
        },
        'fb_sysctl::metadata.rb' => {
          'ExplicitMetadataDepends' => [],
        },
        'fb_unused::metadata.rb' => {
          'ExplicitMetadataDepends' => [],
        },
      }
    end
    let(:metadatajsons) { {} }
    let(:cookbooks) do
      {
        'fb_apache' => {},
        'fb_helpers' => {},
        'fb_init' => {},
        'fb_sysctl' => {},
        'fb_unused' => {},
      }
    end

    it 'returns cookbooks that no other cookbook depends on' do
      result = report.to_a
      expect(result).to include('fb_apache')
      expect(result).to include('fb_unused')
      expect(result).not_to include('fb_helpers')
      expect(result).not_to include('fb_init')
      expect(result).not_to include('fb_sysctl')
    end
  end
end
