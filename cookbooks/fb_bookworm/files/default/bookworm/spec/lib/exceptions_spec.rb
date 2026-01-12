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
require_relative '../spec_helper'
require 'bookworm/exceptions'

describe Bookworm::ClassLoadError do
  it 'is a subclass of RuntimeError' do
    expect(described_class.superclass).to eq(RuntimeError)
  end

  it 'can be raised and rescued' do
    expect { fail described_class, 'test message' }.to raise_error(
      described_class, 'test message'
    )
  end
end
