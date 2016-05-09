# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

use_inline_resources

def whyrun_supported?
  true
end

action :run do
  case new_resource.instance
  when 'system'
    execute 'reload systemd system instance' do
      command '/bin/systemctl daemon-reload'
    end
  when 'user'
    unless node['fb']['sessions'] && node['fb']['sessions']['by_user']
      Chef::Log.info('Requested to reload systemd user instance for all ' +
                     'users, but there are no sessions to reload')
      return
    end
    logged_in = node['fb']['sessions']['by_user'].keys
    if new_resource.user
      unless logged_in.include?(new_resource.user)
        Chef::Log.info('Requested to reload systemd user instance for ' +
                       "#{new_resource.user} but it's not a logged in user")
        return
      end
      users = [new_resource.user]
    else
      users = node['fb']['sessions']['by_user'].to_hash.keys.sort
    end
    users.each do |user|
      unless node['etc']['passwd'][user]
        fail "fb_systemd_reload: user '#{user}' is not defined, aborting."
      end
      bus_path =
        "/run/user/#{node['etc']['passwd'][user]['uid']}/bus"
      execute "reload systemd --user for #{user}" do
        only_if { ::File.exists?(bus_path) }
        command '/bin/systemctl --user daemon-reload'
        environment 'DBUS_SESSION_BUS_ADDRESS' => "unix:path=#{bus_path}"
        user user
        # This can fail if the session is in a weird state, which is fine, as
        # it'll get respawned of the next login (which has the same effect of
        # a reload).
        ignore_failure true
      end
    end
  else
    fail "fb_systemd_reload: instance type '#{new_resource.instance}' is not" +
      'supported!'
  end
end
