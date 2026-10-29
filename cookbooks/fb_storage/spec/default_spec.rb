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
require_relative '../libraries/storage'

recipe 'fb_storage::default', :unsupported => [:mac_os_x] do |tc|
  # The attributes file inspects the build host's mounts.
  before(:each) do
    allow(FB::Storage).to receive(:eligible_devices).and_return([])
  end

  let(:chef_run) do
    tc.chef_run do |node|
      node.automatic['platform'] = 'centos'
      node.automatic['platform_version'] = '8'
    end
  end

  it 'installs the rtxfs helpers and the replaced disks directory' do
    chef_run.converge('fb_systemd::reload', described_recipe)
    %w{/sbin/mount.rtxfs /sbin/fsck.rtxfs}.each do |helper|
      expect(chef_run).to create_cookbook_file(helper).with(:mode => '0755')
    end
    expect(chef_run).to create_directory(
      FB::Storage::REPLACED_DISKS_DIR,
    ).with(:mode => '0755')
  end
end
