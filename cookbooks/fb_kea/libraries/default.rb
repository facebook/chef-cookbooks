#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2025-present, Phil Dibowitz
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
  class Kea
    def self.fail_for_dupe_key(key)
      fail 'fb_kea: While generating the config, it seems we found ' +
        "'#{key}' and '#{key}-hash' at the same level of the config. " +
        'Thus we are failing to generate the config as this will cause ' +
        'unpredictable overwriting of part of your config. Please always ' +
        'use the -hash variety. See README.md for more details.'
    end

    def self.config_verifier(node, type, path)
      case type
      when 'control-agent'
        verify_cmd = 'kea-ctrl-agent'
      else
        verify_cmd = "kea-dhcp#{type == 'ddns' ? '-ddns' : type}"
      end
      cmds = ["#{verify_cmd} -t #{path} 2>&1"]
      # we SPECIFICALLY check for true, not truthy values. If someone
      # mis-types 'auto', we don't want that interpreted as true
      if node['fb_kea']['verify_aa_workaround'] == true
        # Disable AppArmor briefly so it can access /tmp
        # The sleep is because there's a race condition of we do that
        # and immediately run the command
        cmds.unshift("aa-complain #{verify_cmd} &>/dev/null", 'sleep 1')
        cmds.push(
          # save the return value of the actual verify command
          # before losing it to aa-enforce
          'retval=$?',
          "aa-enforce #{verify_cmd} &>/dev/null",
          'exit $retval',
        )
      end
      command = cmds.join('; ')
      Chef::Log.debug("fb_kea[#{verify_cmd}]: verify command is #{command}")
      s = Mixlib::ShellOut.new(command).run_command
      if s.error?
        Chef::Log.info(
          "fb_kea[#{verify_cmd}] Verification failed. The command was: " +
          "#{command}. The output was: #{s.stdout}",
        )
      end
      s.exitstatus == 0
    end

    def self.generate_config(node, type)
      case type
      when 'ddns'
        name = "Dhcp#{type.capitalize}"
        data = self.expand_hash(node['fb_kea']['config'][type].to_h)
      when 'control-agent'
        name = type.capitalize
        data = self.expand_hash(node['fb_kea']['config'][type].to_h)
        if data['control-sockets']
          Chef::Log.warning(
            'fb_kea[control-agent]: Overwriting "control-sockets" portion ' +
            'of configuration. You should not specify this. See README.md ' +
            'for details.',
          )
        end
        data['control-sockets'] = {}
        %w{4 6}.each do |fam|
          if node['fb_kea']["enable_dhcp#{fam}"]
            data['control-sockets']["dhcp#{fam}"] = FB::Helpers.merge_hash(
              node['fb_kea']['config']['_common']['control-socket'].to_h,
              node['fb_kea']['config']["dhcp#{fam}"]['control-socket'].to_h,
            )
          end
        end
        if node['fb_kea']['enable_ddns']
          data['control-sockets']['d2'] =
            node['fb_kea']['config']['control-socket']
        end
      else
        name = "Dhcp#{type}"
        merged_config = FB::Helpers.merge_hash(
          node['fb_kea']['config']['_common'].to_h,
          node['fb_kea']['config']["dhcp#{type}"].to_h,
        )
        data = self.expand_hash(merged_config)
      end
      { name => data }
    end

    # collapses all '-hash' keys into arrays
    def self.expand_hash(data)
      case data
      when Hash
        data.each_with_object({}) do |(key, value), result|
          # First, recursively transform the value in case it contains
          # nested structures.
          transformed_value = expand_hash(value)

          # Check if the key ends with "-hash"
          if key.to_s.end_with?('-hash') && transformed_value.is_a?(Hash)
            next if transformed_value.empty?
            # Remove the "-hash" suffix from the key
            new_key = key.to_s.sub(/-hash$/, '')
            # safety check
            fail_for_dupe_key(new_key) if result[new_key]
            # Replace the value with an array of values from the nested hash
            result[new_key] = transformed_value.values
          else
            # safety check
            fail_for_dupe_key(key) if result[key]
            # Otherwise, keep the original key and transformed value.
            result[key] = transformed_value
          end
        end
      when Array
        # If the data is an array, transform each element.
        data.map { |elem| expand_hash(elem) }
      else
        # For any other data types, return them as-is.
        data
      end
    end
  end
end
