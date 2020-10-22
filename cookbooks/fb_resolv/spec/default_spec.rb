# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
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

recipe 'fb_resolv::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  it 'with empty resolv' do
    chef_run.converge(described_recipe)
    expect(chef_run).to(
      render_file('/etc/resolv.conf').with_content do |content|
        expect(content).to eq(tc.fixture('resolv_empty'))
      end,
    )
  end

  it 'with everything set' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_resolv']['domain'] = 'mydomain.doesnotexist'
      node.default['fb_resolv']['search'] = [
        'mydomain.doesnotexist',
        'myotherdomain.alsodoesnotexist',
      ]
      node.default['fb_resolv']['sortlist'] = [
        '192.0.2.0/255.255.255.0',
        '198.51.100.0',
      ]
      node.default['fb_resolv']['nameservers'] = ['2001:DB8::1', '2001:DB8::2']
      node.default['fb_resolv']['options'] = { 'inet6' => nil, 'ndots' => '3' }
    end
    expect(chef_run).to(
      render_file('/etc/resolv.conf').with_content do |content|
        expect(content).to eq(tc.fixture('resolv_everything_set'))
      end,
    )
  end
end
