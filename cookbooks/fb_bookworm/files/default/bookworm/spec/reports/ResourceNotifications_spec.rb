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

describe Bookworm::Reports::ResourceNotifications do
  let(:mock_kb) { MockKnowledgeBase.new(:resources => resources, :recipes => recipes) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no resources or recipes' do
    let(:resources) { {} }
    let(:recipes) { {} }

    it 'returns empty array' do
      expect(report.to_a).to eq([])
    end

    it 'output returns empty array' do
      expect(report.output).to eq([])
    end
  end

  describe 'with resources and recipes having notifications' do
    let(:resources) do
      {
        'fb_apache::config' => {
          'ResourceNotifications' => ['service[apache2]', 'template[httpd.conf]'],
        },
      }
    end
    let(:recipes) do
      {
        'fb_helpers::default' => {
          'ResourceNotifications' => ['service[syslog]'],
        },
        'fb_apache::default' => {
          'ResourceNotifications' => ['service[apache2]'],
        },
      }
    end

    it 'returns sorted unique notifications' do
      expect(report.to_a).to eq([
        'service[apache2]',
        'service[syslog]',
        'template[httpd.conf]',
      ])
    end

    it 'output returns sorted unique notifications' do
      expect(report.output).to eq([
        'service[apache2]',
        'service[syslog]',
        'template[httpd.conf]',
      ])
    end
  end
end
