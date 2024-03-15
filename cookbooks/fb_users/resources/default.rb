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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action [:manage]

action_class do
  def bootstrap_pgroups
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
          "fb_users: Will not bootstrap group #{grp} since it exists, and has" +
          ' the right GID',
        )
        next
      end

      info = node['fb_users']['groups'][grp]

      # We may not have this group if it's a remote one, so check we do and
      # that it's set to create
      if info && info['action'] && info['action'] != :delete
        group "bootstrap #{grp}" do # rubocop:disable Chef/Meta/ResourceReplacer
          group_name grp
          gid ::FB::Users::GID_MAP[grp]['gid']
          action :create
          # we'll likely modify the group below, but if it has no members and no
          # comment, then we won't, so lets hook up the notifies in both places
          # just in case
          info['notifies']&.each_value do |notif|
            timing = notif['timing'] || 'delayed'
            notifies notif['action'].to_sym, notif['resource'], timing.to_sym
          end
        end
      else
        Chef::Log.debug(
          "fb_users: Will not bootstrap group #{grp} since it is marked for " +
          'deletion',
        )
        next
      end
    end
  end
end

action :manage do
  # The idea of primary groups doesn't exist on windows, so none of this
  # is necessary
  unless node.windows?
    bootstrap_pgroups
  end

  begin
    data_bag_passwords = data_bag('fb_users_auth')
  rescue Net::HTTPServerException
    data_bag_passwords = {}
  end

  set_passwords = !node.windows? || node['fb_users']['set_passwords_on_windows']

  # Now we can add all the users
  node['fb_users']['users'].each do |username, info|
    # helper variables
    mapinfo = ::FB::Users::UID_MAP[username]
    pgroup = info['gid'] || node['fb_users']['user_defaults']['gid']
    unless info['only_if'].nil?
      unless info['only_if'].instance_of?(Proc)
        fail "fb_users's only_if requires a Proc for #{username}"
      end
      next unless info['only_if'].call
    end
    homedir = info['home'] || "/home/#{username}"
    homedir_group = info['homedir_group'] || pgroup
    # If `manage_home` isn't set, we'll use a user-specified default.
    # If *that* isn't set, use the filesystem type to determine
    manage_homedir = info['manage_home']
    if manage_homedir.nil?
      if node['fb_users']['user_defaults']['manage_home'].nil?
        manage_homedir = true
        unless node.windows?
          homebase = ::File.dirname(homedir)
          if node['filesystem']['by_mountpoint'][homebase]
            homebase_type =
              node['filesystem']['by_mountpoint'][homebase]['fs_type']
            if homebase_type.start_with?('nfs', 'autofs')
              manage_homedir = false
            end
          end
        end
      else
        manage_homedir = node['fb_users']['user_defaults']['manage_home']
      end
    end

    # delete any users and optionally clean up home dirs if `manage_home true`
    if info['action'] == :delete
      # keep property list in sync with FB::Users._validate
      user username do # rubocop:disable Chef/Meta/ResourceReplacer
        manage_home manage_homedir
        action :remove
        info['notifies']&.each_value do |notif|
          timing = notif['timing'] || 'delayed'
          notifies notif['action'].to_sym, notif['resource'], timing.to_sym
        end
      end
      next
    end

    pass = info['password']
    if !pass && data_bag_passwords.include?(username)
      Chef::Log.debug("fb_users[#{username}]: Using password from data_bag")
      pass = data_bag_item('fb_users_auth', username)['password']
    end

    # disabling fc009 because it triggers on 'secure_token' below which
    # is already guarded by a version 'if'
    user username do # rubocop:disable Chef/Meta/ResourceReplacer
      uid mapinfo['uid'].to_i
      # the .to_i here is important - if the usermap accidentally
      # quotes the gid, then it will try to look up a group named "142"
      # or whatever.
      #
      # We explicityly pass in a GID here instead of a name to ensure that
      # as GIDs are moving, we get the intended outcome.
      gid ::FB::Users::GID_MAP[pgroup]['gid'].to_i
      system mapinfo['system'] unless mapinfo['system'].nil?
      shell info['shell'] || node['fb_users']['user_defaults']['shell']
      manage_home manage_homedir
      home homedir
      comment mapinfo['comment'] if mapinfo['comment']
      if pass && set_passwords
        password pass
      end
      if FB::Version.new(Chef::VERSION) >= FB::Version.new('15') &&
          !info['secure_token'].nil?
        secure_token info['secure_token']
      end
      info['notifies']&.each_value do |notif|
        timing = notif['timing'] || 'delayed'
        notifies notif['action'].to_sym, notif['resource'], timing.to_sym
      end
      action :create
    end

    if manage_homedir
      directory homedir do
        owner mapinfo['uid'].to_i
        group ::FB::Users::GID_MAP[homedir_group]['gid'].to_i
        mode info['homedir_mode'] if info['homedir_mode']
        action :create
      end
    end
  end

  # and then converge all groups
  node['fb_users']['groups'].each do |groupname, info|
    unless info['only_if'].nil?
      unless info['only_if'].instance_of?(Proc)
        fail "fb_users's only_if requires a Proc for #{username}"
      end
      next unless info['only_if'].call
    end
    if info['action'] == :delete
      group groupname do # rubocop:disable Chef/Meta/ResourceReplacer
        action :remove
        info['notifies']&.each_value do |notif|
          timing = notif['timing'] || 'delayed'
          notifies notif['action'].to_sym, notif['resource'], timing.to_sym
        end
      end
      next
    end

    mapinfo = ::FB::Users::GID_MAP[groupname]
    # disabling fc009 becasue it triggers on 'comment' below which
    # is already guarded by a version 'if'
    group groupname do # rubocop:disable Chef/Meta/ResourceReplacer
      gid mapinfo['gid'].to_i
      system mapinfo['system'] unless mapinfo['system'].nil?
      if info['members']
        if info['members'].instance_of?(Proc)
          members lazy { info['members'].call }
        else
          members info['members']
        end
      end
      if FB::Version.new(Chef::VERSION) >= FB::Version.new('14.9') &&
          mapinfo['comment']
        comment mapinfo['comment']
      end
      info['notifies']&.each_value do |notif|
        timing = notif['timing'] || 'delayed'
        notifies notif['action'].to_sym, notif['resource'], timing.to_sym
      end
      append false
      action :create
    end
  end
end
