# Copyright (c) Meta Platforms, Inc. and affiliates.
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
#

require './spec/spec_helper'
require_relative '../libraries/redacted_string'

describe 'Chef::FB::Helpers' do
  context 'Chef::FB::Helpers::RedactedString' do
    it 'should not return the secret on to_s' do
      expect(FB::Helpers::RedactedString.new('test secret').to_s).to eq('**REDACTED**')
    end
    it 'should not return the secret on to_str' do
      expect(FB::Helpers::RedactedString.new('test secret').to_str).to eq('**REDACTED**')
    end
    it 'should not return the secret on inspect' do
      expect(FB::Helpers::RedactedString.new('test secret').inspect).to eq('"***REDACTED***"')
    end
    it 'should return the secret on value' do
      expect(FB::Helpers::RedactedString.new('test secret').value).to eq('test secret')
    end
    it 'should be frozen' do
      expect(FB::Helpers::RedactedString.new('test secret').frozen?).to eq(true)
    end
  end
end
