# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

module FB
  module Iptables
    TABLES_AND_CHAINS = {
      'mangle' => %w{PREROUTING INPUT OUTPUT FORWARD POSTROUTING},
      'filter' => %w{INPUT OUTPUT FORWARD},
      'raw'    => %w{PREROUTING OUTPUT},
    }

    # Is the given rule valid for the give ip version
    def self.rule_supports_ip_version?(rule, version)
      return true unless rule['ip']
      return true if rule['ip'] == version
      rule['ip'].is_a?(Array) && rule['ip'].include?(version)
    end

    def self.each_table(for_ip, node)
      FB::Iptables::TABLES_AND_CHAINS.each do |table, _chains|
        chains = node['fb_iptables'][table].to_hash
        # 'only' is a purposefully not publicly documented attribute
        # thou can to a table, to have this table only used for a
        # specific ip version
        # It allows you for example to remove any mention of the
        # *nat table in ip6tables if the box only have the ipv4 nat
        # module installed.
        #
        # node.default['fb_iptables']['nat']['only'] = 4
        # The nat table chains/policies won't be written in
        # /etc/sysconfig/ip6tables

        # We delete it not to have a 'only' table
        only = chains.delete('only')
        if only.nil? || only == for_ip
          yield(table, chains)
        end
      end
    end

    # walk dynamic chains and return all dynamic chains enabled for this
    # table/chain combination.
    #
    # For example, for filter/INPUT, we include any chains under 'filter' with
    # 'INPUT' in it's enabled list.
    def self.get_dynamic_chains(table, chain, node)
      dynamic = node['fb_iptables']['dynamic_chains'][table].to_hash
      dynamic.map do |dynamic_chain, enabled_for|
        dynamic_chain if enabled_for.include?(chain)
      end.compact
    end
  end
end
