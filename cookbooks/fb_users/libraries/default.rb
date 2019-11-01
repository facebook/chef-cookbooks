#
# Copyright (c) 2019-present, Vicarious, Inc.
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
      unless node['fb_users']['users'] || node['fb_users']['groups']
        return
      end

      uids = {}
      UID_MAP.each do |user, info|
        if uids[info['uid']]
          fail "fb_users[user]: User #{user} in UID map has a UID conflict"
        end

        uids[info['uid']] = nil
      end

      gids = {}
      GID_MAP.each do |group, info|
        if gids[info['gid']]
          fail "fb_users[group]: group #{group} in GID map has a GID conflict"
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
      node['fb_users']['groups'].keys.sort.uniq do |group|
        unless GID_MAP[group]
          fail "fb_users[group]: Group #{group} has no GID in the GID_MAP"
        end
      end
    end
  end
end
