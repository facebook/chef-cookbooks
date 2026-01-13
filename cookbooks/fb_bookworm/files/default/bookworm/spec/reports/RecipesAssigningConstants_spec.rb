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

describe Bookworm::Reports::RecipesAssigningConstants do
  let(:mock_kb) { MockKnowledgeBase.new(:recipes => recipes) }
  let(:report) { described_class.allocate.tap { |r| r.instance_variable_set(:@kb, mock_kb) } }

  describe 'with no recipes' do
    let(:recipes) { {} }

    it 'returns empty string' do
      expect(report.output).to eq('')
    end
  end

  describe 'with recipes assigning constants' do
    let(:recipes) do
      {
        'fb_helpers::default' => {
          'RecipeConstantAssignments' => [],
        },
        'fb_init::default' => {
          'RecipeConstantAssignments' => ['MY_CONSTANT'],
        },
        'fb_apache::setup' => {
          'RecipeConstantAssignments' => ['APACHE_CONFIG', 'VHOST_DEFAULT'],
        },
      }
    end

    it 'returns recipes with constants' do
      output = report.output
      expect(output).to include('fb_init::default MY_CONSTANT')
      expect(output).to include('fb_apache::setup APACHE_CONFIG, VHOST_DEFAULT')
      expect(output).not_to include('fb_helpers::default')
    end
  end
end
