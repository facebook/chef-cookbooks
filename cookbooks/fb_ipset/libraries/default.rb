# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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

require 'set'

module FB
  module IPset
    def self.get_existing_ipsets
      save = Mixlib::ShellOut.new('ipset save').run_command
      save.error!

      existing_sets = {}

      save.stdout.split("\n").each do |line|
        words = line.split(' ')

        case words[0]
        # create name-of-set hash:net family inet hashsize 64 maxelem 4
        when 'create'
          set_name = words[1]
          set_type = words[2]
          set_parameters = Hash[words[3..-1].each_slice(2).to_a]

          existing_sets[set_name] = set_parameters
          existing_sets[set_name]['type'] = set_type
          existing_sets[set_name]['members'] = []

        # add name-of-set 1.1.1.1
        when 'add'
          set_name = words[1]
          add_address = words[2]

          existing_sets[set_name]['members'] << add_address
        else
          fail "Unable to parse line #{line}"
        end
      end

      existing_sets
    end

    def self.ipset_to_cmds(name, h)
      local_h = h.clone
      lines = []

      # pop out the type & members
      type = local_h.delete('type')
      members = local_h.delete('members')

      # build out the creation arguments
      args = local_h.map { |k, v| "#{k} #{v}" }.join(' ')
      lines << "ipset create #{name} #{type} #{args}"

      # add members
      members.each do |member|
        lines << "ipset add #{name} #{member}"
      end
      lines
    end
  end
end
