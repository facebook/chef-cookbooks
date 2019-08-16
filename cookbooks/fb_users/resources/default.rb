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

default_action [:manage]

action :manage do
  # You can't add users if their primary group doesn't exist. So, first
  # we find all primary groups, and make sure they exist, or create them
  if node['fb_users']['user_defaults']['gid']
    pgroups = [node['fb_users']['user_defaults']['gid']]
  end
  pgroups += node['fb_users']['users'].map { |_, info| info['gid'] }
  pgroups = pgroups.compact.sort.uniq
  pgroups.each do |grp|
    group "bootstrap #{grp}" do
      group_name grp
      gid ::FB::Users::GID_MAP[grp]['gid']
      action :create
    end
  end

  # Now we can add all the users
  node['fb_users']['users'].each do |username, info|
    mapinfo = ::FB::Users::UID_MAP[username]
    pgroup = info['gid'] || node['fb_users']['user_defaults']['gid']
    homedir = info['home'] || "/home/#{username}"
    # If `manage_homedir` isn't set, we'll use a user-specified default.
    # If *that* isn't set, then
    manage_homedir = nil
    unless info['manage_home']
      if node['fb_users']['user_defaults']['manage_home']
        manage_homedir = node['fb_users']['user_defaults']['manage_home']
      else
        manage_homedir = true
        homebase = ::File.dirname(homedir)
        if node['filesystem']['by_mountpoint'][homebase]
          homebase_type = node['filesystem']['by_mountpoint'][homebase]['fs_type']
          if homebase_type.start_with?('nfs', 'autofs')
            manage_homedir = false
          end
        end
      end
    end

    user username do
      uid mapinfo['uid']
      gid ::FB::Users::GID_MAP[pgroup]['gid']
      shell info['shell'] || node['fb_users']['user_defaults']['shell']
      manage_home manage_homedir
      home homedir
      comment mapinfo['comment'] if mapinfo['comment']
      comment mapinfo['password'] if mapinfo['password']
      action :create
    end
  end

  # and then converge all groups
  node['fb_users']['groups'].each do |groupname, info|
    group groupname do
      gid ::FB::Users::GID_MAP[groupname]['gid']
      members info['members'] if info['members']
      append false
      action :create
    end
  end
end
