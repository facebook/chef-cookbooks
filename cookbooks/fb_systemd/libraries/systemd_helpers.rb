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
      case content
      when Hash
        IniParse.gen do |doc|
          content.each_pair do |sect, opts|
            doc.section(sect) do |section|
              opts.each_pair do |opt, val|
                [val].flatten.each do |v|
                  section.option(opt, v)
                end
              end
            end
          end
        end.to_s
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
          if systemd_overrides[stanza]
            systemd_overrides[stanza].each do |k, override|
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
  end
end
