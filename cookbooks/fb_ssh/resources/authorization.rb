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

action_class do
  def manage(type)
    keydir = FB::SSH::DESTDIR[type]

    directory keydir do
      owner 'root'
      group 'root'
      mode '0755'
    end

    unless node['fb_ssh']["authorized_#{type}_users"].empty?
      allowed_users = node['fb_ssh']["authorized_#{type}_users"]
    end
    if type == 'keys'
      auth_map = Hash[
        data_bag('fb_ssh_authorized_keys').map { |x| [x, nil] }
      ]
    else
      auth_map = node['fb_ssh']["authorized_#{type}"]
    end

    auth_map.each_key do |user|
      next if allowed_users && !allowed_users.include?(user)

      template "#{keydir}/#{user}" do
        source "authorized_#{type}.erb"
        owner 'root'
        group 'root'
        mode '0644'
        if type == 'keys'
          d = data_bag_item('fb_ssh_authorized_keys', user)
          d.delete('id')
          variables({ :data => d })
        else
          variables({ :data => auth_map[user] })
        end
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
