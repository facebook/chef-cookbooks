# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

recipe 'fb_systemd::default', :supported => [:centos7] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  before(:each) do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with('/run/systemd/system').
      and_return(true)
    ml = double('systemctl')
    allow(ml).to receive_messages(
      :run_command => ml,
      :stdout => "multi-user.target\n",
    )
    allow(Mixlib::ShellOut).to receive(:new).with('systemctl get-default').
      and_return(ml)
  end

  it 'should render empty config' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_systemd']['system'] = {
        'DefaultLimitNOFILE' => '666',
        'DefaultTasksAccounting' => true,
      }
    end

    expect(chef_run).to render_file('/etc/systemd/system.conf').with_content(
      tc.fixture('system.conf'),
    )
  end
end
