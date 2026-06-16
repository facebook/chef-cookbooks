# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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
#

require './spec/spec_helper'
require_relative '../libraries/fb_helpers'

describe FB::Helpers do
  describe '.windows?' do
    it 'is truthy on a Windows RUBY_PLATFORM' do
      stub_const('RUBY_PLATFORM', 'x64-mingw-ucrt')
      expect(FB::Helpers.windows?).to be_truthy
    end

    it 'is falsey on a Linux RUBY_PLATFORM' do
      stub_const('RUBY_PLATFORM', 'x86_64-linux')
      expect(FB::Helpers.windows?).to be_falsey
    end
  end

  describe '.linux?' do
    it 'is true on a Linux RUBY_PLATFORM' do
      stub_const('RUBY_PLATFORM', 'x86_64-linux')
      expect(FB::Helpers.linux?).to eq(true)
    end

    it 'is false on a Windows RUBY_PLATFORM' do
      stub_const('RUBY_PLATFORM', 'x64-mingw-ucrt')
      expect(FB::Helpers.linux?).to eq(false)
    end
  end

  # sysnative_path is a class method whose Windows code path was previously
  # never exercised in tests. It must work when `self` is the FB::Helpers
  # class (not a Chef::Node), so drive it purely through platform mocking.
  describe '.sysnative_path' do
    context 'on 64-bit Windows' do
      before(:each) do
        allow(ChefUtils).to receive(:windows?).and_return(true)
        stub_const('RUBY_PLATFORM', 'x64-mingw-ucrt')
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('WINDIR').and_return('C:\\Windows')
      end

      it 'returns the system32 path' do
        expect(FB::Helpers.sysnative_path).to eq('C:\\Windows\\system32\\')
      end
    end

    context 'on 32-bit Windows' do
      before(:each) do
        allow(ChefUtils).to receive(:windows?).and_return(true)
        stub_const('RUBY_PLATFORM', 'i386-mingw32')
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('WINDIR').and_return('C:\\Windows')
      end

      it 'returns the sysnative path' do
        expect(FB::Helpers.sysnative_path).to eq('C:\\Windows\\sysnative\\')
      end
    end

    context 'on a non-Windows platform' do
      before(:each) do
        allow(ChefUtils).to receive(:windows?).and_return(false)
      end

      it 'raises rather than returning a path' do
        expect { FB::Helpers.sysnative_path }.to raise_error(RuntimeError)
      end
    end
  end
end
