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

describe Bookworm::Reports::CookbookDependencyDot do
  let(:mock_kb) { MockKnowledgeBase.new(:metadatarbs => metadatarbs) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no metadata.rb files' do
    let(:metadatarbs) { {} }

    it 'returns empty digraph' do
      expect(report.to_s).to eq("digraph deps {\n\n}")
    end

    it 'output returns empty digraph' do
      expect(report.output).to eq("digraph deps {\n\n}")
    end
  end

  describe 'with metadata.rb files having dependencies' do
    let(:metadatarbs) do
      {
        'fb_helpers::metadata.rb' => {
          'ExplicitMetadataDepends' => ['fb_init'],
        },
        'fb_apache::metadata.rb' => {
          'ExplicitMetadataDepends' => ['fb_helpers', 'fb_sysctl'],
        },
      }
    end

    it 'returns DOT format with dependencies' do
      output = report.to_s
      expect(output).to start_with('digraph deps {')
      expect(output).to end_with('}')
      expect(output).to include('fb_helpers->fb_init')
      expect(output).to include('fb_apache->fb_helpers')
      expect(output).to include('fb_apache->fb_sysctl')
    end

    it 'output returns DOT format' do
      expect(report.output).to eq(report.to_s)
    end
  end
end
