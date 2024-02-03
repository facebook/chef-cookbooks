#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
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
  class Networkmanager
    module Resource
      NM_CONN_DIR = '/etc/NetworkManager/system-connections'.freeze
      PREFIX = 'fb_networkmanager'.freeze

      def conf_path(name, normalize = true)
        if normalize
          n = "#{PREFIX}_#{name.downcase.gsub(' ', '_')}"
        else
          n = name
        end
        ::File.join(NM_CONN_DIR, n)
      end

      def determine_files(name, config)
        cfile = conf_path(name)
        migratefile = fromfile = nil
        if config['_migrate_from']
          migratefile = conf_path(config['_migrate_from'], false)
          # Once we've created a file, we should no longer pay attention to the
          # old file
          if ::File.exist?(cfile)
            fromfile = cfile
          elsif ::File.exist?(migratefile)
            Chef::Log.info(
              "#{PREFIX}: Building #{name} based on #{migratefile}",
            )
            fromfile = migratefile
          else
            # Neither the new file nor the old file exist...
            Chef::Log.warn(
              "#{PREFIX}: We were asked to migrate from #{migratefile} but " +
              'that does not exist, so making a fresh config',
            )
            fromfile = cfile
          end
          config.delete('_migrate_from')
        else
          fromfile = cfile
        end

        return {
          'config' => cfile,
          'from' => fromfile,
          'migrate' => migratefile,
        }
      end

      def allowed_connections(node)
        node['fb_networkmanager']['system_connections'].keys.map do |x|
          "#{PREFIX}_#{x.downcase.gsub(' ', '_')}"
        end
      end

      # the magic here is all DeepMerge and testing this is arguably a bit
      # silly, but since this is the most important part of the whole cookbook,
      # we add a test just to make sure no one ever reverses the arguments or
      # something weird
      def generate_config_hashes(from_file, desired_config)
        defaults = {}
        if desired_config['_defaults']
          defaults = desired_config['_defaults'].dup
          desired_config.delete('_defaults')
        end
        current = {}
        if ::File.exist?(from_file)
          current = IniParse.parse(::File.read(from_file)).to_hash
        end
        interim_config = Chef::Mixin::DeepMerge.merge(defaults, current)
        new_config =
          Chef::Mixin::DeepMerge.merge(interim_config, desired_config)

        [current, new_config]
      end
    end
  end
end
