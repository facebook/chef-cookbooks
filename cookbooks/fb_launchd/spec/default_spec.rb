# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
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

require './spec/spec_helper.rb'

# rubocop:disable Style/MultilineBlockChain

recipe(
  'fb_launchd::default',
  :supported => [:mac_os_x],
  :unsupported => [:centos7],
) do |tc|
  context 'on non-macOS' do
    it 'should raise an error' do
      expect do
        tc.chef_run(:step_into => ['fb_launchd']) do |node|
          allow(node).to receive(:macos?).and_return(false)
        end.converge(described_recipe)
      end.to raise_error(RuntimeError)
    end
  end

  context 'when performing a clean fb_launchd setup' do
    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_launchd']) do |node|
        allow(node).to receive(:macos?).and_return(true)
      end.converge(described_recipe) do |node|
        node.default['fb_launchd'] = {
          'prefix' => 'com.facebook.managed',
          'jobs' => {
            'simple_daemon' => {
              'program_arguments' => ['foo', '1', '2'],
              'start_calendar_interval' => { 'Minute' => 15 },
            },
            'complex_daemon' => {
              'action' => 'create_if_missing',
              'program' => '/usr/local/bin/foo',
              'keep_alive' => true,
              'limit_load_to_session_type' => ['Aqua'],
            },
            'simple_agent' => {
              'program' => '/usr/local/bin/foo',
              'start_calendar_interval' => { 'Minute' => 15 },
              'type' => 'agent',
            },
          },
        }
      end
    end

    it 'should enable daemons' do
      expect(chef_run).to enable_launchd(
        'com.facebook.managed.simple_daemon',
      ).with(
        'program_arguments' => ['foo', '1', '2'],
        'start_calendar_interval' => { 'Minute' => 15 },
      )
    end

    it 'should create daemons with custom actions' do
      expect(chef_run).to create_if_missing_launchd(
        'com.facebook.managed.complex_daemon',
      ).with(
        'program' => '/usr/local/bin/foo',
        'keep_alive' => true,
        'limit_load_to_session_type' => ['Aqua'],
      )
    end

    it 'should enable agents' do
      expect(chef_run).to enable_launchd(
        'com.facebook.managed.simple_agent',
      ).with(
        'program' => '/usr/local/bin/foo',
        'start_calendar_interval' => { 'Minute' => 15 },
        'type' => 'agent',
      )
    end
  end

  context 'when specifying a custom prefix' do
    let(:job_spec) do
      {
        'prefix' => 'io.company',
        'jobs' => {
          'simple_daemon' => {
            'program_arguments' => ['foo', '1', '2'],
          },
        },
      }
    end

    let(:chef_run) do
      tc.chef_run(:step_into => ['fb_launchd']) do |node|
        allow(node).to receive(:macos?).and_return(true)
      end
    end

    it 'should use the custom prefix' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_launchd'] = job_spec
      end
      expect(chef_run).to enable_launchd('io.company.simple_daemon').with(
        'program_arguments' => ['foo', '1', '2'],
      )
    end

    it 'should fail when the prefix ends with .' do
      job_spec['prefix'] = 'io.company.'
      expect do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_launchd'] = job_spec
        end
      end.to raise_error(RuntimeError)
    end
  end

  context 'when using blacklisted attributes' do
    let(:launchd_spec) do
      {
        'prefix' => 'com.facebook.managed',
        'jobs' => {
          'test' => {
            'program' => '/usr/local/bin/foo',
            'start_calendar_interval' => { 'Minute' => 15 },
          },
        },
      }
    end

    let(:chef_run) do
      tc.chef_run(:step_into => ['fb_launchd']) do |node|
        allow(node).to receive(:macos?).and_return(true)
      end
    end

    it 'should fail when parsing label attribute' do
      launchd_spec['jobs']['test']['label'] = 'foo.bar.baz'
      expect do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_launchd'] = launchd_spec
        end
      end.to raise_error(RuntimeError)
    end

    it 'should fail when parsing path attribute' do
      launchd_spec['jobs']['test']['path'] = '/Library/LaunchDaemons/foo.plist'
      expect do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_launchd'] = launchd_spec
        end
      end.to raise_error(RuntimeError)
    end
  end

  context 'when removing unmanaged jobs' do
    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_launchd']) do |node|
        allow(node).to receive(:macos?).and_return(true)
      end.converge(described_recipe) do |node|
        node.default['fb_launchd'] = {
          'prefix' => 'com.facebook.managed',
          'jobs' => {
            'test' => {
              'program' => '/usr/local/bin/foo',
              'start_calendar_interval' => { 'Minute' => 15 },
            },
          },
        }
      end
    end

    before(:each) do
      allow(Dir).to receive(:glob).and_return(
        [
          '/Library/LaunchDaemons/com.apple.daemon1.plist',
          '/Library/LaunchDaemons/com.company.daemon2.plist',
          '/Library/LaunchDaemons/com.facebook.managed.not_test.plist',
        ],
        [
          '/Library/LaunchAgents/com.apple.agent1.plist',
          '/Library/LaunchAgents/com.facebook.managed.also_not_test.plist',
        ],
      )
    end

    it 'should not remove non-prefixed launchds' do
      expect(chef_run).to delete_launchd('com.facebook.managed.not_test').with(
        'path' => '/Library/LaunchDaemons/com.facebook.managed.not_test.plist',
      )
      expect(chef_run).to delete_launchd(
        'com.facebook.managed.also_not_test',
      ).with(
        'path' =>
          '/Library/LaunchAgents/com.facebook.managed.also_not_test.plist',
      )
    end

    it 'should enable prefixed launchds' do
      expect(chef_run).to enable_launchd('com.facebook.managed.test').with(
        'program' => '/usr/local/bin/foo',
        'start_calendar_interval' => { 'Minute' => 15 },
      )
    end
  end
end

# rubocop:enable Style/MultilineBlockChain
