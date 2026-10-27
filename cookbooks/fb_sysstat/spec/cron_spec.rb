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

recipe 'fb_sysstat::cron', :unsupported => [:mac_os_x] do |tc|
  # The fb_timers branch needs FB::Systemd from a cookbook fb_sysstat does not
  # depend on; the mask does not care which scheduler is used.
  let(:chef_run) do
    tc.chef_run do |node|
      allow(node).to receive(:systemd?).and_return(false)
      allow(node).to receive(:centos_min_version?).and_call_original
      allow(node).to receive(:centos_min_version?).with(10).
        and_return(centos10)
    end
  end

  context 'on CentOS 10' do
    let(:centos10) { true }

    it 'masks sysstat-collect.timer' do
      chef_run.converge(described_recipe)
      expect(chef_run).to stop_systemd_unit('sysstat-collect.timer')
      expect(chef_run).to disable_systemd_unit('sysstat-collect.timer')
      expect(chef_run).to mask_systemd_unit('sysstat-collect.timer')
    end
  end

  context 'before CentOS 10' do
    let(:centos10) { false }

    it 'leaves sysstat-collect.timer alone' do
      chef_run.converge(described_recipe)
      expect(chef_run).not_to mask_systemd_unit('sysstat-collect.timer')
    end
  end
end
