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

recipe(
  'fb_fluentbit::default',
  :unsupported => [:mac_os_x],
) do |tc|
  it 'should raise error when parser has no format' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['input']['tail']['foo'] = {
          'Path' => '/var/log/messages',
        }
        node.default['fb_fluentbit']['output']['http']['bar'] = {
          'Match' => '*',
          'Host' => '192.168.0.1',
          'Port' => 80,
          'URI' => '/stuff',
        }
        # Note: no format
        node.default['fb_fluentbit']['parser']['myparser'] = {
          'Time_Key' => 'time',
        }
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when using undefined parser' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['filter']['parser']['parse_stuff'] = {
          'Match' => '*',
          'Parser' => 'nonexistent_parser',
        }
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise error when using undefined parser with mutliple parsers' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['parser']['my_parser'] = {
          'Format' => 'regex',
          'Regex' => '^.+$',
        }
        node.default['fb_fluentbit']['filter']['parser']['parse_stuff'] = {
          'Match' => '*',
          'Parser' => [
            'my_parser',
            'nonexistent_parser',
          ],
        }
      end
    end.to raise_error(RuntimeError)
  end

  it 'should raise on error if multiline_parser rule is missing' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['multiline_parser']['my_multi_parse'] = {
          'type' => 'regex',
          'flush_timeout' => '1000',
          'rules' => [
            {
              'state_name' => 'start_state',
              'pattern' => '/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+ .*$/',
              'next_state' => 'cont',
            },
            {
              'state_name' => 'cont',
              'pattern' => '/^ - .*/',
              'next_state' => 'non_existant_rule',
            },
          ],
        }
      end
    end.to raise_error(/fb_fluentbit: multiline parser .* contains rule errors/)
  end

  it 'should raise on error if multiline_parser start_state rule is missing' do
    expect do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['multiline_parser']['my_multi_parse'] = {
          'type' => 'regex',
          'flush_timeout' => '1000',
          'rules' => [
            {
              'state_name' => 'begin',
              'pattern' => '/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+ .*$/',
              'next_state' => 'cont',
            },
            {
              'state_name' => 'cont',
              'pattern' => '/^ - .*/',
              'next_state' => 'non_existant_rule',
            },
          ],
        }
      end
    end.to raise_error(/fb_fluentbit: multiline parser .* contains rule errors/)
  end

  context 'external plugin with bad config' do
    it 'should raise error when "package" is missing' do
      expect do
        tc.chef_run.converge(described_recipe) do |node|
          node.default['fb_fluentbit']['external']['my_plugin'] = {
            'path' => '/bin/true',
          }
          node.default['fb_fluentbit']['output']['my_plugin']['test'] = {
            'key1' => 'value1',
          }
        end
      end.to raise_error(RuntimeError)
    end

    it 'should raise error when "path" is missing' do
      expect do
        tc.chef_run.converge(described_recipe) do |node|
          node.default['fb_fluentbit']['external']['my_plugin'] = {
            'package' => 'fb-mypackage',
          }
          node.default['fb_fluentbit']['output']['my_plugin']['test'] = {
            'key1' => 'value1',
          }
        end
      end.to raise_error(RuntimeError)
    end
  end

  context 'multiple external plugins' do
    cached(:chef_run) do
      tc.chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['input']['tail']['foo'] = {
          'Path' => '/var/log/messages',
        }
        node.default['fb_fluentbit']['output']['http']['bar'] = {
          'Match' => '*',
          'Host' => '192.168.0.1',
          'Port' => 80,
          'URI' => '/stuff',
        }
        node.default['fb_fluentbit']['filter']['grep']['filter_stuff'] = {
          'Match' => '*',
          'Regex' => 'log aa',
        }
        node.default['fb_fluentbit']['filter']['grep']['filter_more_stuff'] = {
          'Match' => '*',
          'Regex' => 'log bb',
        }

        # Add a couple custom plugins.
        node.default['fb_fluentbit']['external']['custom_plugin'] = {
          'package' => 'my-custom-rpm',
          'path' => '/usr/local/lib/custom_plugin/custom_plugin.so',
        }
        %w{category_1 category_2}.each do |category|
          node.default['fb_fluentbit']['output']['custom_plugin'][category] = {
            'Match' => '*',
            'Category' => category,
          }
        end

        # Now add a made-up external plugin.
        node.default['fb_fluentbit']['external']['not_real'] = {
          'package' => 'my-fake-package',
          'path' => '/usr/local/lib/not_real/not_real.so',
        }
        node.default['fb_fluentbit']['input']['not_real']['foo'] = {
          'Key1' => 'Value1',
          'Key2' => 'Value2',
        }
      end
    end

    it 'should install external plugin packages' do
      expect(chef_run).to upgrade_package('Install fluentbit external plugins').
        with_package_name(['my-custom-rpm', 'my-fake-package'])
    end

    it 'should render plugins.conf' do
      expect(chef_run).to render_file('/etc/fluent-bit/plugins.conf').
        with_content(tc.fixture('multiple_external_plugins_plugins.conf'))
    end

    it 'should render service conf' do
      expect(chef_run).to render_file('/etc/fluent-bit/fluent-bit.conf').
        with_content(tc.fixture('multiple_external_plugins_service.conf'))
    end
  end

  context 'clean config setup' do
    cached(:chef_run) do
      tc.chef_run.converge(described_recipe) do |node|

        # turn on automatic upgrades
        node.default['fb_fluentbit']['manage_packages'] = true

        # Modify some service settings
        node.default['fb_fluentbit']['service_config']['Log_Level'] = 'debug'
        node.default['fb_fluentbit']['service_config']['HTTP_Server'] = 'On'

        # Set up input/output plugins + a filter.
        node.default['fb_fluentbit']['input']['tail']['foo'] = {
          'Path' => '/var/log/messages',
        }
        node.default['fb_fluentbit']['output']['http']['bar'] = {
          'Match' => '*',
          'Host' => '192.168.0.1',
          'Port' => 80,
          'URI' => '/stuff',
        }
        node.default['fb_fluentbit']['filter']['grep']['filter_stuff'] = {
          'Match' => '*',
          'Regex' => 'log aa',
        }
        node.default['fb_fluentbit']['filter']['parser']['parse_foo'] = {
          'Match' => '*',
          'Parser' => 'my_parser',
        }

        # Add an external plugin.
        node.default['fb_fluentbit']['external']['custom_plugin'] = {
          'package' => 'my-custom-rpm',
          'path' => '/usr/local/lib/custom_plugin/custom_plugin.so',
        }
        node.default['fb_fluentbit']['output']['custom_plugin']['foo'] = {
          'Match' => '*',
          'Category' => 'some_category',
        }

        # Add some parsers.
        node.default['fb_fluentbit']['parser']['my_parser'] = {
          'Format' => 'regex',
          'Time_Key' => 'time',
          'Regex' => '^some line here$',
        }
        node.default['fb_fluentbit']['parser']['my_other_parser'] = {
          'Format' => 'json',
          'Time_Key' => 'time',
        }
      end
    end

    it 'should upgrade the package' do
      expect(chef_run).to upgrade_package('fluent-bit')
    end

    it 'should install external plugin packages' do
      expect(chef_run).to upgrade_package('Install fluentbit external plugins').
        with_package_name(['my-custom-rpm'])
    end

    it 'should render parsers.conf' do
      expect(chef_run).to render_file('/etc/fluent-bit/parsers.conf').
        with_content(tc.fixture('clean_config_parsers.conf'))
    end

    it 'should render plugins.conf' do
      expect(chef_run).to render_file('/etc/fluent-bit/plugins.conf').
        with_content(tc.fixture('clean_config_plugins.conf'))
    end

    it 'should render service conf' do
      expect(chef_run).to render_file('/etc/fluent-bit/fluent-bit.conf').
        with_content(tc.fixture('clean_config_service.conf'))
    end

    it 'should start the service' do
      expect(chef_run).to enable_service('fluent-bit')
      expect(chef_run).to start_service('fluent-bit')
    end
  end

  context 'not installing packages' do
    cached(:chef_run) do
      tc.chef_run.converge(described_recipe) do |node|
        # Add a external plugin
        node.default['fb_fluentbit']['external']['custom_plugin'] = {
          'package' => 'my-custom-rpm',
          'path' => '/usr/local/lib/custom_plugin/custom_plugin.so',
        }

        # turn off automatic fluentbit upgrades
        node.default['fb_fluentbit']['manage_packages'] = false

        # turn off external plugin upgrades
        node.default['fb_fluentbit']['plugin_manage_packages'] = false
      end
    end

    it 'should not upgrade the fluentbit package' do
      expect(chef_run).to_not upgrade_package('fluent-bit')
    end

    it 'should not install external plugin packages' do
      expect(chef_run).to_not upgrade_package('fluentbit external plugins').
        with_package_name(['my-custom-rpm'])
    end
  end

  context 'when defining plugins with multiple types' do
    let(:chef_run) { tc.chef_run }

    it 'should render key/value pairs properly' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['input']['systemd']['tail_journal'] = {
          'Tag' => 'my_journal_logs',
          'Systemd_Filter' => {
            '_SYSTEMD_UNIT' => ['unit1.service', 'unit2.service'],
            '_KEY_ONE' => 'value',
          },
        }
      end

      expect(chef_run).to render_file('/etc/fluent-bit/fluent-bit.conf').
        with_content(tc.fixture('systemd_duplicate_keys_service.conf'))
    end

    it 'should render multiple keys properly' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_fluentbit']['filter']['record_modifier']['a'] = {
          'Whitelist_key' => ['foo', 'bar', 'baz'],
        }
      end

      expect(chef_run).to render_file('/etc/fluent-bit/fluent-bit.conf').
        with_content(tc.fixture('record_modifier_duplicate_keys_service.conf'))
    end
  end
end
