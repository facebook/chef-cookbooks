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

recipe 'fb_mlocate::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  context 'on CentOS 8 or 9' do
    before do
      chef_run.node.stub(:centos8?).and_return(false)
      chef_run.node.stub(:centos9?).and_return(true)
    end

    it 'enables and starts the mlocate timer' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_mlocate']['want_mlocate'] = true
      end
      expect(chef_run).to enable_systemd_unit('mlocate-updatedb.timer')
      expect(chef_run).to start_systemd_unit('mlocate-updatedb.timer')
    end
  end

  context 'on CentOS 10' do
    before do
      chef_run.node.stub(:el_min_version?).with(10).and_return(true)
      chef_run.node.stub(:centos8?).and_return(false)
      chef_run.node.stub(:centos9?).and_return(false)
    end

    it 'enables and starts the plocate timer' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_mlocate']['want_mlocate'] = true
      end
      expect(chef_run).to enable_systemd_unit('plocate-updatedb.timer')
      expect(chef_run).to start_systemd_unit('plocate-updatedb.timer')
    end
  end

  context 'on unsupported CentOS releases' do
    before do
      chef_run.node.stub(:centos8?).and_return(false)
      chef_run.node.stub(:centos9?).and_return(false)
    end

    it 'does not manage the unavailable mlocate timer' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_mlocate']['want_mlocate'] = true
      end
      expect(chef_run).not_to enable_systemd_unit('mlocate-updatedb.timer')
      expect(chef_run).not_to start_systemd_unit('mlocate-updatedb.timer')
    end
  end
end
