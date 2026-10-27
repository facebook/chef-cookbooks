# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates.
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

recipe 'fb_ldconfig::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run do |node|
      node.automatic['platform'] = 'centos'
      node.automatic['platform_version'] = '8'
    end
  end

  before(:each) do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/etc/ld.so.conf.d/*').and_return([])
  end

  it 'installs ld.so.conf and relays changes to ldconfig' do
    chef_run.converge(described_recipe)
    expect(chef_run).to create_cookbook_file('/etc/ld.so.conf').with(
      :source => 'ld.so.conf',
      :mode => '0644',
    )
    relay = chef_run.notify_group('run ldconfig after an ld.so.conf change')
    expect(relay).to subscribe_to('cookbook_file[/etc/ld.so.conf]').
      on(:run).immediately
    expect(relay).to notify('execute[ldconfig]').to(:run).immediately
  end
end
