# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
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

default_action :reload

property :instance, :kind_of => String, :default => 'system'
property :user, :kind_of => [String, NilClass], :default => nil

action_class do
  def daemon_reload_or_reexec(action)
    unless node.systemd?
      # The predicate used in this node method looks for /run/systemd/system
      # which is only present on a booted system. This resource is only useful
      # if the system is booted as it interacts with systemd. If the
      # system is not booted, then we can safely skip.
      Chef::Log.info(
        "Requested to #{action} systemd #{new_resource.instance} " +
        'skipped because the system is not booted',
      )
      return
    end
    case new_resource.instance
    when 'system'
      execute "#{action} systemd system instance" do
        command "/bin/systemctl daemon-#{action}"
      end
    when 'user'
      unless node['sessions'] && node['sessions']['by_user']
        Chef::Log.info("Requested to #{action} systemd user instance for all " +
                       "users, but there are no sessions to #{action}")
        return
      end
      logged_in = node['sessions']['by_user'].keys
      if new_resource.user
        unless logged_in.include?(new_resource.user)
          Chef::Log.info("Requested to #{action} systemd user instance for " +
                         "#{new_resource.user} but it's not a logged in user")
          return
        end
        users = [new_resource.user]
      else
        users = node['sessions']['by_user'].to_hash.keys.sort
      end
      failed = false
      users.each do |user|
        begin
          uid = Etc.getpwnam(user).uid
        rescue ArgumentError
          Chef::Log.error(
            "fb_systemd_reload: user '#{user}' is not defined, " +
            'will abort later.',
          )
          failed = true
          next
        end
        bus_path = "/run/user/#{uid}/bus"
        execute "#{action} systemd --user for #{user}" do
          only_if { ::File.exist?(bus_path) }
          command "/bin/systemctl --user daemon-#{action}"
          environment 'DBUS_SESSION_BUS_ADDRESS' => "unix:path=#{bus_path}"
          user user
          # This can fail if the session is in a weird state, which is fine, as
          # it'll get respawned of the next login (which has the same effect
          # as running the action).
          ignore_failure true
        end
      end
      if failed
        fail 'fb_systemd_reload: aborting due to previous failures'
      end
    else
      fail "fb_systemd_reload: instance type '#{new_resource.instance}' " +
        'is not supported!'
    end
  end
end

action :run do
  daemon_reload_or_reexec('reload')
end

action :reload do
  daemon_reload_or_reexec('reload')
end

action :reexec do
  daemon_reload_or_reexec('reexec')
end
