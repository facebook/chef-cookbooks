#
# Copyright (c) 2020-present, Facebook, Inc.
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

require './spec/spec_helper.rb'

recipe('fb_fluentbit::default') do |tc|
  let(:input_plugin) do
    {
      'name' => 'tail',
      'type' => 'input',
      'plugin_config' => {
        'Path' => '/var/log/messages',
      },
    }
  end

  let(:output_plugin) do
    {
      'name' => 'http',
      'type' => 'output',
      'plugin_config' => {
        'Match' => '*',
        'Host' => '192.168.0.1',
        'Port' => 80,
        'URI' => '/stuff',
      },
    }
  end

  let(:filter_plugin) do
    {
      'name' => 'grep',
      'type' => 'filter',
      'plugin_config' => {
        'Match' => '*',
        'Regex' => 'log aa',
      },
    }
  end

  it 'should raise error with empty config' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins'] = {}
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when defining only input plugin' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins']['foo'] = input_plugin
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when defining only output plugin' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins']['foo'] = output_plugin
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when using incorrect plugin type' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins']['foo'] = input_plugin
        node.default['fb_fluentbit']['plugins']['bar'] = output_plugin
        # Note: incorrect plugin type.
        node.default['fb_fluentbit']['plugins']['baz'] = {
          'type' => 'stuff',
          'Match' => '*',
          'Regex' => 'log aa',
        }
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when defining unnamed plugin' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins']['foo'] = input_plugin
        node.default['fb_fluentbit']['plugins']['bar'] = output_plugin
        # Note: no name (should be: 'grep')
        node.default['fb_fluentbit']['plugins']['baz'] = {
          'type' => 'filter',
          'Match' => '*',
          'Regex' => 'log aa',
        }
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when parser has no format' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['plugins']['foo'] = input_plugin
        node.default['fb_fluentbit']['plugins']['bar'] = output_plugin
        node.default['fb_fluentbit']['parsers']['parser'] = {
          'Time_Key' => 'time',
        }
      end
    end.to raise_error(RuntimeError)
  end

  context 'clean config setup' do
    cached(:chef_run) do
      tc.chef_run.converge(described_recipe) do |node|
        # Modify some service settings
        node.default['fb_fluentbit']['service_config']['Log_Level'] = 'debug'
        node.default['fb_fluentbit']['service_config']['HTTP_Server'] = 'On'

        # Set up input/output plugins + a filter.
        node.default['fb_fluentbit']['plugins']['foo'] = input_plugin
        node.default['fb_fluentbit']['plugins']['bar'] = output_plugin
        node.default['fb_fluentbit']['plugins']['baz'] = filter_plugin

        node.default['fb_fluentbit']['plugins']['foo'] = {
          'name' => 'tail',
          'type' => 'input',
          'plugin_config' => {
            'Path' => '/var/log/messages',
          },
        }

        # Add the scribble external plugin.
        node.default['fb_fluentbit']['plugins']['scribble'] = {
          'name' => 'scribble',
          'type' => 'output',
          'external_path' => '/usr/local/lib/scribble/scribble.so',
          'package_name' => 'fb-fluentbit-scribble-plugin',
          'plugin_config' => {
            'Match' => '*',
            'ScribbleMode' => 'thrift',
            'Category' => 'some_category',
          },
        }

        # Add some parsers.
        node.default['fb_fluentbit']['parsers']['my_parser'] = {
          'format' => 'regex',
          'Time_Key' => 'time',
          'Regex' => '^some line here$',
        }
        node.default['fb_fluentbit']['parsers']['my_other_parser'] = {
          'format' => 'json',
          'Time_Key' => 'time',
        }
      end
    end

    it 'should upgrade the package' do
      expect(chef_run).to upgrade_package('td-agent-bit')
    end

    it 'should install external plugin packages' do
      expect(chef_run).to upgrade_package('fluentbit external plugins').
        with_package_name(['fb-fluentbit-scribble-plugin'])
    end

    it 'should render parsers.conf' do
      expect(chef_run).to render_file('/etc/td-agent-bit/parsers.conf').
        with_content(tc.fixture('clean_config_parsers.conf'))
    end

    it 'should render plugins.conf' do
      expect(chef_run).to render_file('/etc/td-agent-bit/plugins.conf').
        with_content(tc.fixture('clean_config_plugins.conf'))
    end

    it 'should render service conf' do
      expect(chef_run).to render_file('/etc/td-agent-bit/td-agent-bit.conf').
        with_content(tc.fixture('clean_config_service.conf'))
    end

    it 'should start the service' do
      expect(chef_run).to enable_service('td-agent-bit')
      expect(chef_run).to start_service('td-agent-bit')
    end
  end
end
