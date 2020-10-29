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

module FB
  class Fluentbit
    VALID_PLUGIN_TYPES = ['INPUT', 'OUTPUT', 'PARSER', 'FILTER'].freeze

    def self.valid_configuration?(plugins)
      plist = plugins.values
      unless plist.find { |p| p['type'].upcase == 'INPUT' } &&
        plist.find { |p| p['type'].upcase == 'OUTPUT' }
        fail 'fb_fluentbit: ' +
          'You are supposed to have at least one each input and output plugins'
      end
    end

    def self.valid_parser?(parser_name, parser_conf)
      unless parser_conf.key?('format')
        fail "fb_fluentbit: Found invalid fluentbit parser '#{parser_name}'" +
          'with no \'format\' attribute'
      end
      true
    end

    def self.valid_plugin?(plugin_conf)
      unless plugin_conf['name']
        fail 'fb_fluentbit: ' +
          "Found invalid fluentbit plugin configuration with no 'name'" +
          "attribute: #{plugin_conf}"
      end

      config = plugin_conf.to_hash['plugin_config']
      unless config&.is_a?(Hash)
        fail 'fb_fluentbit: ' +
          "Fluentbit plugin '#{plugin_conf['name']}'" +
          " does not have properly configured 'plugin_config' attribute"
      end

      unless VALID_PLUGIN_TYPES.include?(plugin_conf.fetch('type', '').upcase)
        fail 'fb_fluentbit: ' +
          "Invalid plugin type values for '#{plugin_conf['name']}'" +
          ' fluentbit plugin configuation'
      end

      if (plugin_conf['external_path'] || plugin_conf['package_name']) &&
        (!plugin_conf['external_path'] || !plugin_conf['package_name'])
        fail 'fb_fluentbit: ' +
          "If fluentbit plugin '#{plugin_conf['name']}'" +
          'is defined as external, then it must have' +
          " both non empty 'external_path' and 'package_name' attrs"
      end
      true
    end
  end
end
