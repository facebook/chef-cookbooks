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

describe Bookworm::InferRules::MetadatarbAttributeLiterals do
  let(:ast) do
    generate_ast(<<~RUBY)
    name "fb_example"
    maintainer "Dave"
    maintainer_email "dave@example.org"
  RUBY
  end
  it 'captures the metadata literals' do
    rule = described_class.new({ 'ast' => ast })
    expect(rule.output).to eq(
      {
        :name => 'fb_example',
        :maintainer => 'Dave',
        :maintainer_email => 'dave@example.org',
      },
                             )
  end
end
