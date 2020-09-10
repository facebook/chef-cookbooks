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

require './spec/spec_helper.rb'

# rubocop:disable Style/MultilineBlockChain

recipe 'fb_timers::default', :unsupported => [:mac_os_x] do |tc|
  let(:t_path) { '/etc/systemd/timers/' }
  let(:s_path) { '/etc/systemd/system/' }
  let(:unit_types) { %w{timer service} }
  let(:dir_content) { %w{README} }
  let(:timer_jobs) { %w{multiple simple complex params onboot} }

  before do
    [t_path, s_path].each do |path|
      allow(::Dir).to receive(:glob).with("#{path}*").
        and_return(dir_content.map { |f| "#{path}#{f}" })
    end
    dir_content.each do |unit|
      allow(File).to receive(:symlink?).with("#{s_path}#{unit}").
        and_return(true)
      allow(File).to receive(:readlink).with("#{s_path}#{unit}").
        and_return("#{t_path}#{unit}")
    end
    ml = double('systemctl')
    allow(ml).to receive_messages(
      :run_command => ml,
      :stdout => "multi-user.target\n",
    )
    allow(Mixlib::ShellOut).to receive(:new).with('systemctl get-default').
      and_return(ml)
  end

  context 'not managed by systemd' do
    let(:chef_run) do
      tc.chef_run(:step_into => ['fb_timers_setup']) do |node|
        allow(node).to receive(:systemd?).and_return(false)
      end
    end

    it 'should raise an error' do
      expect { chef_run.converge(described_recipe) }.
        to raise_error(RuntimeError)
    end
  end

  context 'missing required key' do
    let(:chef_run) do
      tc.chef_run(:step_into => ['fb_timers_setup']) do |node|
        allow(node).to receive(:systemd?).and_return(true)
      end.converge(described_recipe) do |node|
        node.default['fb_timers']['jobs'] = {
          'no calendar' => {
            'command' => '/usr/local/bin/foobar.sh',
          },
        }
      end
    end

    it 'should raise an error' do
      expect { chef_run.converge(described_recipe) }.
        to raise_error(RuntimeError)
    end
  end

  context 'clean timer setup' do
    cached(:chef_run) do
      tc.chef_run(
        :step_into => ['fb_timers_setup'],
      ) do |node|
        allow(node).to receive(:systemd?).and_return(true)
      end.converge(described_recipe) do |node|
        node.default['fb_timers']['jobs'] = {
          'simple' => {
            'calendar' => '*:0/15:0',
            'command' => '/usr/local/bin/foobar.sh',
          },
          'valid_user_set' => {
            'calendar' => '*:0/15:0',
            'command' => '/usr/local/bin/foobar.sh',
            'service_options' => { 'User' => 'nobody' },
          },
          'complex' => {
            'calendar' => 'Sat,Thu,Mon..Wed,Sat..Sun',
            'command' => '/usr/local/bin/foobar.sh thing1 thing2',
            'timeout' => '1d',
            'timeout_stop' => '1h',
            'accuracy' => '1h',
            'persistent' => true,
            'splay' => '0.5h',
            'syslog' => true,
          },
          'params' => {
            'calendar' => '0:0:0',
            'command' => '/usr/local/bin/foobar.sh',
            'description' => 'Custom set description field',
            'timer_options' => {
              'foo' => '19',
              'bar' => '17',
            },
            'timer_unit_options' => {
              'jkl' => 'aaaaah',
            },
            'service_options' => {
              'asdf' => '7',
              'baz' => '11',
              'foobar' => ['1', '2', '3'],
            },
            'service_unit_options' => {
              'jkl' => 'aaaaah',
              'barbaz' => ['a', 'b', 'c'],
            },
          },
          'no_start' => {
            'calendar' => '1',
            'command' => 'foo',
            'autostart' => false,
          },
          'no_proc' => {
            'calendar' => '1',
            'command' => 'foo',
            'only_if' => proc { false },
          },
          'yes_proc' => {
            'calendar' => '1',
            'command' => 'foo',
            'only_if' => proc { true },
          },
          'multiple' => {
            'calendar' => 'Mon,Wed',
            'commands' => [
              '/usr/local/bin/foobar.sh one',
              '/usr/local/bin/foobar.sh two',
            ],
          },
          'onboot' => {
            'command' => '/usr/local/bin/foobar.sh',
            'timer_options' => { 'OnBootSec' => '1s' },
          },
        }
      end
    end

    it 'should create timer unit files' do
      unit_types.each do |type|
        timer_jobs.each do |job|
          expect(chef_run).to render_file("#{t_path}#{job}.#{type}").
            with_content(tc.fixture("#{job}.#{type}"))
        end
      end
    end

    # TODO: T23654032 add a test to validate this correctly notifies
    # fb_systemd_reload[system instance] to run immediately

    it 'should create symlink for service units' do
      unit_types.each do |type|
        timer_jobs.each do |job|
          expect(chef_run).to run_execute(
            "link unit file #{t_path}#{job}.#{type}",
          )
        end

        expect(chef_run).to_not run_execute(
          "link unit file #{t_path}no_start.#{type}",
        )
      end
    end

    # TODO: T23654032 add a test to validate this correctly notifies
    # fb_systemd_reload[system instance] to run immediately

    it 'should enable the timer unit' do
      timer_jobs.each do |job|
        expect(chef_run).to enable_service("#{job}.timer")
        expect(chef_run).to_not enable_service("#{job}.service")
      end
    end

    it 'should start the timer unit' do
      timer_jobs.each do |job|
        expect(chef_run).to start_service("#{job}.timer")
        expect(chef_run).to_not start_service("#{job}.service")
      end
    end

    it 'should handle jobs with only_ifs' do
      unit_types.each do |type|
        expect(chef_run).to_not render_file("#{t_path}no_proc.#{type}")
        expect(chef_run).to render_file("#{t_path}yes_proc.#{type}")
      end
    end
  end

  context 'prints warnings' do
    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_timers_setup']) do |node|
        allow(node).to receive(:systemd?).and_return(true)
      end.converge(described_recipe) do |node|
        node.stub(:systemd?).and_return(true)
        node.default['fb_timers']['jobs'] = {
          'bad_keys' => {
            'calendar' => '1',
            'command' => 'foo',
            'autostart' => false,
            'FOO' => 'bad',
            'USER' => 'bad',
            'user' => 'bad',
            'User' => 'bad',
          },
        }
      end
    end

    it 'should issue warnings for unknown keys' do
      # We can't be sure of ordering and state so we can't
      # really make this test more specific without getting flakey
      expect(Chef::Log).to receive(:warn).with(/fb_timers:/).at_least(2).times
      chef_run
    end
  end

  context 'removes unmanaged jobs' do
    let(:dir_content) do
      %w{
        README
        old.timer old.service current.timer current.service
        only_if_disabled.timer only_if_disabled.service
        only_if_enabled.timer only_if_enabled.service
      }
    end

    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_timers_setup']) do |node|
        allow(node).to receive(:systemd?).and_return(true)
      end.converge(described_recipe) do |node|
        node.stub(:systemd?).and_return(true)
        node.default['fb_timers']['jobs'] = {
          'current' => {
            'calendar' => 1,
            'command' => 'bar',
          },
          # If the only_if becomes false, in which case we should disable
          'only_if_disabled' => {
            'only_if' => proc { false },
            'calendar' => 1,
            'command' => 'bar',
          },
          'only_if_enabled' => {
            'only_if' => proc { true },
            'calendar' => 1,
            'command' => 'bar',
          },
        }
      end
    end

    it 'should disable the old service units' do
      unit_types.each do |type|
        expect(chef_run).to disable_service("old.#{type}")
        expect(chef_run).to disable_service("only_if_disabled.#{type}")
        expect(chef_run).to_not disable_service("current.#{type}")
        expect(chef_run).to_not disable_service("only_if_enabled.#{type}")
      end
    end

    it 'should stop the old service units' do
      unit_types.each do |type|
        expect(chef_run).to stop_service("old.#{type}")
        expect(chef_run).to stop_service("only_if_disabled.#{type}")
        expect(chef_run).to_not stop_service("current.#{type}")
        expect(chef_run).to_not stop_service("only_if_enabled.#{type}")
      end
    end

    it 'should delete the old timer units' do
      unit_types.each do |type|
        expect(chef_run).to delete_file("#{t_path}old.#{type}")
        expect(chef_run).to delete_file("#{t_path}only_if_disabled.#{type}")
        expect(chef_run).to_not delete_file("#{t_path}current.#{type}")
        expect(chef_run).to_not delete_file("#{t_path}only_if_enabled.#{type}")
      end
    end

    it 'should not delete the README' do
      expect(chef_run).to_not delete_file('README')
    end
  end
end
# rubocop:enable Style/MultilineBlockChain
