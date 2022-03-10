# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2022-present, Facebook, Inc.
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

recipe 'fb_logrotate::default', :unsupported => [:mac_os_x] do |tc|
  let(:logrotate_config) { '/etc/logrotate.d/fb_logrotate.conf' }

  context 'config generation' do
    let(:chef_run) do
      tc.chef_run do |node|
        allow(node).to receive(:systemd?).and_return(true)
        node.automatic['platform'] = 'rhel'
      end
    end

    it 'should create a default logrotate config' do
      expect(Chef::Log).not_to receive(:warn).with(/fb_logrotate:/)
      chef_run.converge(described_recipe)
      expect(chef_run).to render_file(logrotate_config).
        with_content(tc.fixture('fb_logrotate_default.conf'))
    end

    it 'should create a customized logrotate config' do
      expect(Chef::Log).not_to receive(:warn).with(/fb_logrotate:/)
      chef_run.converge(described_recipe) do |node|
        node.default['fb_logrotate']['globals']['maxage'] = '3'
        node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
          'files' => ['/var/log/rsyslog-stats.log'],
          'overrides' => {
            'missingok' => true,
          },
        }
        node.default['fb_logrotate']['configs']['weekly-thing'] = {
          'files' => ['/var/log/weekly.log'],
          'overrides' => {
            'rotation' => 'weekly',
          },
        }
        node.default['fb_logrotate']['configs']['with-size'] = {
          'files' => ['/var/log/sized.log'],
          'overrides' => {
            'size' => '10M',
          },
        }
      end
      expect(chef_run).to render_file(logrotate_config).
        with_content(tc.fixture('fb_logrotate_custom.conf'))
      # confirm we have the translated 4 rotations
      expect(chef_run).to render_file(logrotate_config).
        with_content(/rotate 4/)
      # confirm size translated
      expect(chef_run).to render_file(logrotate_config).
        with_content(/size 10M/)
    end

    it 'should remove redudant nocompress override' do
      expect(Chef::Log).not_to receive(:warn).with(/fb_logrotate:/)
      chef_run.converge(described_recipe) do |node|
        node.default['fb_logrotate']['globals']['nocompress'] = true
        node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
          'files' => ['/var/log/rsyslog-stats.log'],
          'overrides' => {
            'nocompress' => true,
          },
        }
      end
      overrides = chef_run.node['fb_logrotate']['configs']['rsyslog-stats'][
        'overrides']
      expect(overrides).to eq({})
    end

    it 'should warn when an unknown override is used' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
          'files' => ['/var/log/rsyslog-stats.log'],
          'overrides' => {
            'bogusname' => true,
          },
        }
      end
      expect(Chef::Log).to receive(:warn).
        with(/fb_logrotate:\[rsyslog-stats\]:/)
      expect(chef_run).to render_file(logrotate_config).with_content('global')
    end

    it 'should fail when files overlap between configs' do
      expect do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
            'files' => ['/var/log/rsyslog-stats.log'],
          }
          node.default['fb_logrotate']['configs']['my-rsyslog-stats'] = {
            'files' => ['/var/log/rsyslog-stats.log'],
          }
        end
      end.to raise_error(RuntimeError,
                         /fb_logrotate: there are duplicate logrotate configs!/)
    end

    it 'should fail when rotation and size are both set' do
      expect do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_logrotate']['configs']['rsyslog-stats'] = {
            'files' => ['/var/log/rsyslog-stats.log'],
            'overrides' => {
              'rotation' => 'weekly',
              'size' => '10M',
            },
          }
        end
      end.to raise_error(RuntimeError,
                         /you can only use size or rotation/)
    end
  end
end
