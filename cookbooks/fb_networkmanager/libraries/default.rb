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

require 'iniparse'

module FB
  class Networkmanager
    def self.active_connections
      return {} unless ::File.exist?('/usr/bin/nmcli')

      s = Mixlib::ShellOut.new('nmcli -t conn show --active').run_command
      return {} if s.error?

      cons = {}
      s.stdout.each_line do |line|
        name, uuid, type, device = line.strip.split(':')
        cons[name] = {
          'uuid' => uuid,
          'type' => type,
          'device' => device,
        }
      end
      cons
    end

    def self.to_ini(content)
      IniParse.gen do |doc|
        content.each_pair do |sect, opts|
          doc.section(sect, :option_sep => '=') do |section|
            opts.each_pair do |opt, val|
              v = [val].flatten.join(',')
              section.option(opt, v)
            end
          end
        end
      end.to_s
    end
  end
end
