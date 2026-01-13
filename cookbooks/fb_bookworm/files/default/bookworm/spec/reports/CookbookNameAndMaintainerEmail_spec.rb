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

describe Bookworm::Reports::CookbookNameAndMaintainerEmail do
  let(:mock_kb) { MockKnowledgeBase.new(:metadatarbs => metadatarbs) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no metadata.rb files' do
    let(:metadatarbs) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with metadata.rb files having name and maintainer_email' do
    let(:metadatarbs) do
      {
        'fb_helpers::metadata.rb' => {
          'MetadatarbAttributeLiterals' => {
            :name => 'fb_helpers',
            :maintainer_email => 'team@example.com',
          },
        },
        'fb_apache::metadata.rb' => {
          'MetadatarbAttributeLiterals' => {
            :name => 'fb_apache',
            :maintainer_email => 'webteam@example.com',
          },
        },
      }
    end

    it 'returns sorted CSV format' do
      result = report.to_a
      expect(result).to eq([
        'fb_apache,webteam@example.com',
        'fb_helpers,team@example.com',
      ])
    end

    it 'output returns sorted CSV format' do
      expect(report.output).to eq([
        'fb_apache,webteam@example.com',
        'fb_helpers,team@example.com',
      ])
    end
  end
end
