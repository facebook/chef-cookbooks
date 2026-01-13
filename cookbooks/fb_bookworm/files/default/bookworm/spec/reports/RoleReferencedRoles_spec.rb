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

describe Bookworm::Reports::RoleReferencedRoles do
  let(:mock_kb) { MockKnowledgeBase.new(:roles => roles) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no roles' do
    let(:roles) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with roles referencing other roles' do
    let(:roles) do
      {
        'base_role' => {
          'RoleExplicitRoles' => ['common_role', 'security_role'],
        },
        'web_role' => {
          'RoleExplicitRoles' => ['base_role', 'common_role'],
        },
      }
    end

    it 'returns sorted unique role names' do
      expect(report.to_a).to eq([
        'base_role',
        'common_role',
        'security_role',
      ])
    end

    it 'output returns sorted unique role names' do
      expect(report.output).to eq([
        'base_role',
        'common_role',
        'security_role',
      ])
    end
  end
end
