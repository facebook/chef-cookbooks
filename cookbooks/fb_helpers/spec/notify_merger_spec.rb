# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Facebook, Inc.
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

recipe 'fb_helpers::notify_merger_spec', :unsupported => [:mac_os_x] do |tc|
  nm_resource = 'ruby block 3'

  it 'should trigger notifications when the fb_notify_merger resource is updated' do
    chef_run = tc.chef_run(
      :step_into => ['fb_notify_merger', 'ruby_block'],
    )

    chef_run.converge(described_recipe)

    expect(chef_run.fb_notify_merger(nm_resource)).to be_updated
    expect(chef_run.fb_notify_merger(nm_resource)._update).to be true
    expect(chef_run.ruby_block('some ruby block 3')).to be_updated
  end

  it 'should not trigger notifications when the fb_notify_merger resource is not updated' do
    chef_run = tc.chef_run(
      :step_into => ['fb_notify_merger'],
    )

    chef_run.converge(described_recipe)

    expect(chef_run.fb_notify_merger(nm_resource)).not_to be_updated
    expect(chef_run.fb_notify_merger(nm_resource)._update).to be false
    expect(chef_run.ruby_block('some ruby block 3')).not_to be_updated
  end

  it 'should fail if update is called out of order' do
    chef_run = tc.chef_run(
      :step_into => ['fb_notify_merger', 'ruby_block'],
    ) do |node|
      node.default['guard_update'] = true
    end

    expect do
      chef_run.converge(described_recipe)
    end.to raise_error(RuntimeError, /update was called against an already-merged notify_merger!/)
  end

  it 'should fail if merge is called out of order' do
    chef_run = tc.chef_run(
      :step_into => ['fb_notify_merger', 'ruby_block'],
    ) do |node|
      node.default['guard_merge'] = true
    end

    expect do
      chef_run.converge(described_recipe)
    end.to raise_error(RuntimeError, /merge was called against an already-merged notify_merger!/)
  end
end
