# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
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

require './spec/spec_helper'

recipe 'fb_screen::packages', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  it 'upgrades the screen package' do
    chef_run.converge(described_recipe)
    expect(chef_run).to upgrade_package('screen')
  end
end
