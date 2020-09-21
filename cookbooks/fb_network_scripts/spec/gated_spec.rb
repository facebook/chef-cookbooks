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

recipe 'fb_network_scripts::spec', :unsupported => [:mac_os_x] do |tc|

  # hack for t70172554
  stubs_for_provider('template[/tmp/testfile]') do |provider|
    allow(provider).
      to receive_shell_out('/usr/sbin/selinuxenabled', { :returns => [0, 1] })
  end

  # fb_network_scripts_gated_template internally inspects whether the resource
  # actually ran, so we have to step in to it and the template resource.
  # Stepping into 'template' means the spec will actually change things
  # on the running system, which is very bad, so we cause that to fail
  # purposefully with a bad user id.
  it 'should try to update the template when nw changes are allowed' do
    chef_run = tc.chef_run(
      :step_into => ['fb_network_scripts_gated_template', 'template'],
    ) do |node|
      allow_any_instance_of(Chef::Node).to receive(:nw_changes_allowed?).
        and_return(true)
    end
    expect { chef_run.converge(described_recipe) }.
      to raise_error(Chef::Exceptions::UserIDNotFound)
  end

  it 'should not modify the template when nw changes are not allowed' do
    chef_run = tc.chef_run(
      :step_into => ['fb_network_scripts_gated_template'],
    ) do |node|
      allow_any_instance_of(Chef::Node).to receive(:nw_changes_allowed?).
        and_return(false)
    end
    chef_run.converge(described_recipe)
    expect(chef_run).not_to render_file('/tmp/testfile')
  end
end
