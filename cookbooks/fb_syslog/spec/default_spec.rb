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
#
require './spec/spec_helper'

recipe 'fb_syslog::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run do |node|
      node.default['shard_seed'] = 12345
    end
  end

  context 'render /etc/rsyslog.conf' do
    def reset_attributes(node)
      node.default['fb_syslog']['syslog-entries'] = {}
      node.default['fb_syslog']['rsyslog_facilities_sent_to_remote'] = []
      node.default['fb_syslog']['rsyslog_upstream'] = ''
    end

    it 'with empty attributes' do
      chef_run.converge('fb_systemd::reload', described_recipe) do |node|
        reset_attributes(node)
      end

      expect(chef_run).to render_file('/etc/rsyslog.conf').
        with_content(tc.fixture('rsyslog.conf_empty'))
    end

    it 'with syslog entries' do
      chef_run.converge('fb_systemd::reload', described_recipe) do |node|
        reset_attributes(node)
        node.default['fb_syslog']['syslog-entries'] = {
          'test' => {
            'comment' => 'this is a test entry',
            'selector' => 'local1.info',
            'action' => '-/var/log/test.log',
          },
        }
      end

      expect(chef_run).to render_file('/etc/rsyslog.conf').
        with_content(tc.fixture('rsyslog.conf'))
    end

    it 'with custom facilities' do
      chef_run.converge('fb_systemd::reload', described_recipe) do |node|
        reset_attributes(node)
        node.default['fb_syslog'][
          'rsyslog_facilities_sent_to_remote'] << 'kern.*'
        node.default['fb_syslog'][
          'rsyslog_upstream'] = 'syslog.vip.facebook.com'
      end

      expect(chef_run).to render_file('/etc/rsyslog.conf').
        with_content(tc.fixture('rsyslog-kern.conf'))
    end
  end
end
