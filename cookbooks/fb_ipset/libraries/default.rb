# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

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

      return existing_sets
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
      return lines
    end
  end
end
