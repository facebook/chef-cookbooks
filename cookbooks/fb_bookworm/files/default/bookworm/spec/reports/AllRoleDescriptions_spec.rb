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

describe Bookworm::Reports::AllRoleDescriptions do
  let(:mock_kb) { MockKnowledgeBase.new(:roles => roles) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no roles' do
    let(:roles) { {} }

    it 'returns empty string' do
      expect(report.to_plain).to eq('')
    end
  end

  describe 'with roles having descriptions' do
    let(:roles) do
      {
        'web_role' => {
          'RoleDescription' => 'Web server configuration',
        },
        'base_role' => {
          'RoleDescription' => 'Base system settings',
        },
      }
    end

    it 'returns sorted roles with descriptions' do
      output = report.to_plain
      expect(output).to include('role: base_role desc: Base system settings')
      expect(output).to include('role: web_role desc: Web server configuration')
      expect(output.index('base_role')).to be < output.index('web_role')
    end
  end
end
