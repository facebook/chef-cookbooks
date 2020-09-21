#
# Copyright (c) 2019-present, Vicarious, Inc.
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
  class Users
    # To be called at runtime only.
    def self._validate(node)
      # if they're not using the API to add users or groups, then
      # don't fail on them not defining UID_MAP and GID_MAP
      if node['fb_users']['users'].empty? && node['fb_users']['groups'].empty?
        return
      end

      uids = {}
      UID_MAP.each do |user, info|
        if uids[info['uid']]
          fail "fb_users[user]: User #{user} in UID map has a UID conflict"
        end

        if defined?(RESERVED_UID_RANGES)
          RESERVED_UID_RANGES.each do |identifier, range|
            if range.include?(info['uid'])
              fail "fb_users[user]: User #{user} in UID map is in the " +
                "reserved range for '#{identifier}'"
            end
          end
        end
        uids[info['uid']] = nil
      end

      gids = {}
      GID_MAP.each do |group, info|
        if gids[info['gid']]
          fail "fb_users[group]: group #{group} in GID map has a GID conflict"
        end

        if defined?(RESERVED_GID_RANGES)
          RESERVED_GID_RANGES.each do |identifier, range|
            if range.include?(info['gid'])
              fail "fb_users[group]: Group #{group} in GID map is in the " +
                "reserved range for '#{identifier}'"
            end
          end
        end
        uids[info['gid']] = nil
      end

      if node['fb_users']['user_defaults']['gid']
        gid = node['fb_users']['user_defaults']['gid']
        unless GID_MAP[gid]
          fail "fb_users[user]: Default group #{gid} has no GID in the " +
            'GID_MAP - update, or unset it.'
        end
      end

      node['fb_users']['users'].each do |user, info|
        unless [nil, :add, :delete].include?(info['action'])
          fail "fb_users[users]: User #{user} has unknown action #{action}"
        end

        if info['action'] == :delete
          if info.keys.count > 1
            fail "fb_users[user]: User #{user} has action :delete, but also " +
              "other keys: #{info}"
          end
          next
        end

        unless UID_MAP[user]
          fail "fb_users[user]: User #{user} has no UID in the UID_MAP"
        end

        if info['gid']
          gid = info['gid']
          unless GID_MAP[gid]
            fail "fb_users[user]: User #{user} has a group of #{gid} which " +
              'is not in the GID_MAP'
          end
          gid_int = false
          # rubocop:disable Style/DoubleNegation
          # rubocop:disable Lint/HandleExceptions
          begin
            gid_int = !!Integer(gid)
          rescue ArgumentError
            # expected
          end
          # rubocop:enable Style/DoubleNegation
          # rubocop:enable Lint/HandleExceptions

          if gid_int
            fail "fb_users[user]: User #{user} has an integer for primary" +
              ' group. Please specify a name.'
          end
        elsif !node['fb_users']['user_defaults']['gid']
          fail "fb_users[user]: User #{user} has no primary group (gid) " +
            'and there is no default set.'
        end
      end
      node['fb_users']['groups'].each do |group, info|
        unless [nil, :add, :delete].include?(info['action'])
          fail "fb_users[group]: Group #{group} has unknown action #{action}"
        end

        if info['action'] == :delete
          if info.keys.count > 1
            fail "fb_users[group]: Group #{group} has action :delete, but " +
              "also other keys: #{info}"
          end
          next
        end
        unless GID_MAP[group]
          fail "fb_users[group]: Group #{group} has no GID in the GID_MAP"
        end
      end
    end

    def self.gid_to_gname(gid)
      GID_MAP.select { |_, info| info['gid'] == gid }.keys.first
    end

    def self.uid_to_uname(uid)
      UID_MAP.select { |_, info| info['uid'] == uid }.keys.first
    end

    def self.initialize_group(node, group)
      if node['fb_users']['groups'][group] &&
          node['fb_users']['groups'][group]['action'] != :delete
        Chef::Log.debug(
          "fb_users: Group #{group} already initialized, doing nothing",
        )
        return
      end
      node.default['fb_users']['groups'][group] = {
        'members' => [],
        'action' => :add,
      }
    end
  end
end
