# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

chef_rt_protos_path = '/etc/iproute2/rt_protos.d/chef.conf'.freeze

recipe 'fb_iproute::rt_protos', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  it 'default rt_protos chef.conf' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_iproute']['rt_protos_ids'] = { 'openr' => 99 }
    end

    expect(chef_run).to render_file(chef_rt_protos_path).with_content(
      tc.fixture('default_chef.conf'),
    )
  end
end
