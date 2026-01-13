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

describe Bookworm::Reports::LibraryDefinedModulesAndClassConstants do
  let(:mock_kb) { MockKnowledgeBase.new(:libraries => libraries) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no libraries' do
    let(:libraries) { {} }

    it 'returns header only' do
      expect(report.output).to eq("file\tmodules\tconstants\n")
    end
  end

  describe 'with libraries having modules and constants' do
    let(:libraries) do
      {
        'fb_helpers::default' => {
          'LibraryDefinedModuleConstants' => ['FB', 'FB::Helpers'],
          'LibraryDefinedClassConstants' => ['FB::Helpers::Utils'],
        },
        'fb_apache::helpers' => {
          'LibraryDefinedModuleConstants' => ['FB::Apache'],
          'LibraryDefinedClassConstants' => [],
        },
      }
    end

    it 'returns sorted libraries with modules and constants' do
      output = report.output
      expect(output).to start_with("file\tmodules\tconstants\n")
      expect(output).to include("fb_apache::helpers:\tFB::Apache\t")
      expect(output).to include("fb_helpers::default:\tFB,FB::Helpers\tFB::Helpers::Utils")
    end
  end
end
