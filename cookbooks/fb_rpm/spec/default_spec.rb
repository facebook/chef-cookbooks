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

recipe 'fb_rpm::default', :unsupported => [:centos6, :mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run do |node|
      node.default['shard_seed'] = 0
    end
  end

  context 'render /etc/rpm/macros' do
    before(:each) do
      allow(Chef::Provider::Package::Yum::YumCache.instance).
        to receive(:package_available?).with('rpm-plugin-selinux').
        and_return(true)
    end

    it 'with empty macros' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_rpm']['macros'] = {}
      end
      expect(chef_run).to render_file('/etc/rpm/macros').
        with_content(tc.fixture('rpm_macros_empty'))
    end

    it 'with set macros' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_rpm']['macros'] = {
          '%somestuff' => 1,
          '%other_stuff' => 'some string',
          '%no_value' => nil,
        }
      end
      expect(chef_run).to render_file('/etc/rpm/macros').
        with_content(tc.fixture('rpm_macros_custom'))
    end
  end
end
