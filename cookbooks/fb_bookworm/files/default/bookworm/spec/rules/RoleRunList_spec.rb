# Copyright (c) 2022-present, Meta Platforms, Inc. and affiliates
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

describe Bookworm::InferRules::RoleRunList do
  let(:ast) do
    generate_ast(<<~RUBY)
    name "fake role"
    description "This is a fake role"

    run_list(
      'role[foo]',
      'recipe[bar]',
    )
  RUBY
  end
  it 'captures the run list from a role' do
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(['role[foo]', 'recipe[bar]'])
  end
end
