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
#

require 'iniparse'
require 'shellwords'

module FB
  class Systemd
    def self.condition_user_online(user)
      # see https://www.freedesktop.org/wiki/Software/systemd/NetworkTarget/
      user_has_session = self.condition_user_session(user)
      return {
        'After' => 'network-online.target',
        'Wants' => 'network-online.target',
      }.merge(user_has_session)
    end

    def self.condition_user_session(user)
      # this should hopefully be implemented upstream at some point, maybe as
      # ConditionUserSession
      if user.is_a?(Integer)
        uid = user
      else
        # throws ArgumentError if the username is invalid
        user_entry = ::Etc.getpwnam(user)
        uid = user_entry.uid
      end
      return { 'ConditionPathExists' => "/run/user/#{uid}/bus" }
    end

    def self.path_to_unit(path, unit_type)
      cmd = [
        '/bin/systemd-escape',
        '--path',
        "--suffix=#{unit_type}",
        path,
      ]
      return Mixlib::ShellOut.new(cmd).run_command.stdout.chomp
    end

    def self.sanitize(name)
      name.gsub(/[^[a-zA-Z0-9]]/, '_')
    end

    # this is based on
    # https://github.com/chef/chef/blob/61a8aa44ac33fc3bbeb21fa33acf919a97272eb7/lib/chef/resource/systemd_unit.rb#L66-L83
    def self.to_ini(content)
      append_sections = ''
      case content
      when Hash
        IniParse.gen do |doc|
          content.each_pair do |sect, opts|
            case opts
            when Hash
              doc.section(sect) do |section|
                opts.each_pair do |opt, val|
                  [val].flatten.each do |v|
                    section.option(opt, v)
                  end
                end
              end
            when Array
              opts.each do |o|
                append_sections << "\n" << IniParse.gen do |d|
                  d.section(sect) do |section|
                    o.each_pair do |opt, val|
                      [val].flatten.each do |v|
                        section.option(opt, v)
                      end
                    end
                  end
                end.to_s
              end
            end
          end
        end.to_s + append_sections
      else
        IniParse.parse(content.to_s).to_s
      end
    end

    def self.merge_unit(default_systemd_settings, systemd_overrides)
      merged = {
        'Service' => {},
        'Unit' => {},
        'Install' => {},
      }
      default_systemd_settings.each do |k, v|
        merged[k] = v.clone
      end
      if systemd_overrides
        ['Service', 'Unit', 'Install'].each do |stanza|
          systemd_overrides[stanza]&.each do |k, override|
            default = merged[stanza][k]
            # If either value is a list, append them together
            list = override.is_a?(Array) || default.is_a?(Array)
            if list
              merged[stanza][k] = Array(default) + Array(override)
            else
              # Override
              merged[stanza][k] = override
            end
          end
        end
      end

      # Remove empty keys in the systemd_overrides
      merged.reject! { |_k, v| v.empty? }

      # Sort the stanzas so reordering the keys doesn't alter the
      # returned hash structure
      ['Service', 'Unit', 'Install'].each do |stanza|
        merged[stanza] = merged[stanza].sort.to_h if merged[stanza]
      end

      merged
    end

    def self.get_unit_properties(unit)
      property_map = {}
      Mixlib::ShellOut.new("systemctl show #{unit}").run_command.stdout.lines.each do |line|
        key, value = line.split('=')
        property_map[key] = value
      end

      property_map
    end
  end
end
