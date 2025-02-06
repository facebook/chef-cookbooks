# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

recipe 'fb_helpers::spec', :unsupported => [:mac_os_x] do |tc|
  # fb_helpers_gated_template internally inspects whether the resource
  # actually ran, so we have to step in to it

  template_path = '/tmp/testfile'

  it 'should try to update the template when nw changes are allowed' do
    chef_run = tc.chef_run(
      :step_into => ['fb_helpers_gated_template'],
    ) do |_|
      allow_any_instance_of(Chef::Node).to receive(:nw_changes_allowed?).
        and_return(true)
      # Since fb_helpers_gated_template uses `updated_by_last_action?` and
      # whyrun to extrapolate if a change will happen, we have to mock it
      allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
      allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
    end

    expect(FB::Helpers).not_to receive(:_request_nw_changes_permission)

    allow(Chef::Log).to receive(:info).and_call_original
    expect(Chef::Log).to receive(:info).with(/fb_helpers: changes are allowed/)

    chef_run.converge(described_recipe)

    expect(chef_run).to render_file(template_path).with_content(
      tc.fixture('gated_template_network'),
    )

    # Notifications still work as expected because resource properly updates
    expect(chef_run.fb_helpers_gated_template(template_path)).to notify(
      'service[critical_service]',
    ).to(:restart).immediately
  end

  it 'should not modify the template when nw changes are not allowed' do
    chef_run = tc.chef_run(
      :step_into => ['fb_helpers_gated_template'],
    ) do |_|
      allow_any_instance_of(Chef::Node).to receive(:nw_changes_allowed?).
        and_return(false)
      allow(Chef::Resource::Template).to receive(:updated_by_last_action?).and_call_original
      allow_any_instance_of(Chef::Resource::Template).to receive(:updated_by_last_action?).and_return(true)
    end

    expect(FB::Helpers).to receive(:_request_nw_changes_permission)

    allow(Chef::Log).to receive(:info).and_call_original
    expect(Chef::Log).to receive(:info).with(/fb_helpers: not allowed to change configs/)

    chef_run.converge(described_recipe)

    expect(chef_run).not_to render_file(template_path)

    expect(chef_run.fb_helpers_gated_template(template_path)).not_to be_updated
  end
end
