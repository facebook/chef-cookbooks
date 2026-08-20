#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

action_class do
  def manage(type)
    keydir = ::File.join(FB::SSH.confdir(node), FB::SSH::DESTDIR[type])

    directory keydir do
      unless node.windows?
        owner 'root'
        group node.root_group
        mode '0755'
      end
    end

    unless node['fb_ssh']["authorized_#{type}_users"].empty?
      allowed_users = node['fb_ssh']["authorized_#{type}_users"]
    end
    auth_map = {}
    if type == 'keys'
      data_bag('fb_ssh_authorized_keys').each do |user|
        keys = data_bag_item('fb_ssh_authorized_keys', user)['keys']
        auth_map[user] = keys if keys
      end
      auth_map.merge!(node['fb_ssh']['authorized_keys'])
    else
      auth_map = node['fb_ssh']["authorized_#{type}"]
    end

    auth_map.each do |user, keys|
      next if allowed_users && !allowed_users.include?(user)

      key_map = node['fb_ssh']['authorized_keys_key_map'][user]
      if node['fb_ssh']['require_key_map'] && !key_map
        Chef::Log.debug(
          "Skipping all keys for #{user}, they have no keymap, but " +
          'require_key_map is set',
        )
        next
      end

      keys.select! { |k| key_map.include?(k) } if key_map

      # windows sucks and on ssh the "username" is "corp\\whatever" which is
      # not a valid file name. Ugh. So we leave it in the user's homedir
      if node.windows?
        user = user.split('\\').last
        homedir = "C:/Users/#{user}"
        keyfile = "#{homedir}/.ssh/authorized_keys"
        # users who don't have homedirectories, we skip
        next unless ::File.exist?(homedir)

        directory "#{homedir}/.ssh" do
          rights :read, user
          rights :full_control, 'Administrators'
          inherits false
        end
      else
        keyfile = "#{keydir}/#{user}"
      end

      template keyfile do
        source "authorized_#{type}.erb"
        if node.windows?
          rights :read, user
          rights :full_control, 'Administrators'
          inherits false
        else
          owner 'root'
          group node.root_group
          mode '0644'
        end
        variables({ :data => auth_map[user] })
      end
    end

    Dir.glob("#{keydir}/*").each do |keyfile|
      user = ::File.basename(keyfile)
      if allowed_users
        next if allowed_users.include?(user)
      elsif auth_map[user]
        next
      end
      file keyfile do
        action :delete
      end
    end
  end
end

action :manage_keys do
  manage('keys')
end

action :manage_principals do
  manage('principals')
end
