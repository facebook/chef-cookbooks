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

default_action [:manage]

action :manage do
  # You can't add users if their primary group doesn't exist. So, first
  # we find all primary groups, and make sure they exist, or create them
  if node['fb_users']['user_defaults']['gid']
    pgroups = [node['fb_users']['user_defaults']['gid']]
  end
  pgroups += node['fb_users']['users'].map { |_, info| info['gid'] }
  pgroups = pgroups.compact.sort.uniq
  Chef::Log.debug(
    'fb_users: the following groups are GIDs and may need bootstrapping: ' +
    "#{pgroups.join(', ')}.",
  )
  pgroups.each do |grp|
    if node['etc']['group'][grp] &&
        node['etc']['group'][grp]['gid'] == ::FB::Users::GID_MAP[grp]['gid']
      Chef::Log.debug(
        "fb_users: Will not bootstrap group #{grp} since it exists, and has " +
        'the right GID',
      )
      next
    end

    # We may not have this group if it's a remote one, so check we do and
    # that it's set to create

    if node['fb_users']['groups'][grp] &&
        node['fb_users']['groups'][grp]['action'] &&
        node['fb_users']['groups'][grp]['action'] != :delete

      group "bootstrap #{grp}" do # ~FB015
        group_name grp
        gid ::FB::Users::GID_MAP[grp]['gid']
        action :create
      end
    else
      Chef::Log.debug(
        "fb_users: Will not bootstrap group #{grp} since it is marked for " +
        'deletion',
      )
      next
    end
  end

  begin
    data_bag_passwords = data_bag('fb_users_auth')
  rescue Net::HTTPServerException
    data_bag_passwords = {}
  end

  # Now we can add all the users
  node['fb_users']['users'].each do |username, info|
    if info['action'] == :delete
      user username do # ~FB014
        action :remove
      end
      next
    end
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
          homebase_type =
            node['filesystem']['by_mountpoint'][homebase]['fs_type']
          if homebase_type.start_with?('nfs', 'autofs')
            manage_homedir = false
          end
        end
      end
    end

    pass = mapinfo['password']
    if !pass && data_bag_passwords.include?(username)
      Chef::Log.debug("fb_users[#{username}]: Using password from data_bag")
      pass = data_bag_item('fb_users_auth', username)['password']
    end

    user username do # ~FB014
      uid mapinfo['uid']
      # the .to_i here is important - if the usermap accidentally
      # quotes the gid, then it will try to look up a group named "142"
      # or whatever.
      #
      # We explicityly pass in a GID here instead of a name to ensure that
      # as GIDs are moving, we get the intended outcome.
      gid ::FB::Users::GID_MAP[pgroup]['gid'].to_i
      shell info['shell'] || node['fb_users']['user_defaults']['shell']
      manage_home manage_homedir
      home homedir
      comment mapinfo['comment'] if mapinfo['comment']
      password pass if pass
      action :create
    end
  end

  # and then converge all groups
  node['fb_users']['groups'].each do |groupname, info|
    if info['action'] == :delete
      group groupname do # ~FB015
        action :remove
      end
      next
    end
    # disableing fc009 becasue it triggers on 'comment' below which
    # is already guarded by a version 'if'
    group groupname do # ~FC009 ~FB015
      gid ::FB::Users::GID_MAP[groupname]['gid']
      members info['members'] if info['members']
      if FB::Version.new(Chef::VERSION) >= FB::Version.new('14.9')
        comment info['comment'] if info['comment']
      end
      append false
      action :create
    end
  end
end
