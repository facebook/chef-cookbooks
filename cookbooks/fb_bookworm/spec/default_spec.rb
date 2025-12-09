# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates
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

recipe 'fb_bookworm::default', :unsupported => [:mac_os_x] do |tc|
  include FB::Spec::Helpers

  let(:chef_run) do
    tc.chef_run
  end

  it 'creates the bookworm executable' do
    chef_run.converge(described_recipe)
    expect(chef_run).to create_cookbook_file('/usr/local/bin/bookworm').with(
      :source => 'bookworm.sh',
      :owner => 'root',
      :group => 'root',
      :mode => '0755',
    )
  end

  it 'creates the bookworm library directory' do
    chef_run.converge(described_recipe)
    expect(chef_run).to create_remote_directory('/usr/local/lib/bookworm').with(
      :source => 'bookworm',
      :purge => true,
      :owner => 'root',
      :group => 'root',
      :mode => '0755',
    )
  end
end
