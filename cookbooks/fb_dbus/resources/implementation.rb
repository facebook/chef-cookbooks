# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
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
property :implementation, ['dbus-daemon', 'dbus-broker']

default_action :setup

load_current_value do
  s = Mixlib::ShellOut.new('systemctl -q is-active dbus-broker')
  s.run_command
  if s.exitstatus.zero?
    implementation 'dbus-broker'
  # 3 == inactive
  # 4 == does not exist
  elsif [3, 4].include?(s.exitstatus)
    implementation 'dbus-daemon'
  else
    fail "fb_dbus: invalid status for dbus-broker: #{s.exitstatus}"
  end
end

action :setup do
  wanted_impl = new_resource.implementation
  current_impl = current_resource.implementation

  # Only enable dbus-daemon if it's the wanted implementation; if it's also the
  # current one, ensure it's started
  if wanted_impl == 'dbus-daemon'
    dbus_action = [:enable]
    if current_impl == 'dbus-daemon'
      dbus_action << :start
    end
  else
    dbus_action = [:disable]
  end

  if node.centos7? || node.centos8?
    dbus_daemon_svc = 'dbus'
  else
    # On CentOS Stream 9, this socket needs to be explicitly enabled for
    # dbus-broker to work properly
    systemd_unit 'dbus.socket' do
      action [:enable, :start]
    end

    dbus_daemon_svc = 'dbus-daemon'
  end

  service dbus_daemon_svc do
    action dbus_action
  end

  # Only enable dbus-broker if it's the wanted implementation; if it's also the
  # current one, ensure it's started
  if wanted_impl == 'dbus-broker'
    dbus_broker_action = [:enable]
    if current_impl == 'dbus-broker'
      dbus_broker_action << :start
    end
  else
    dbus_broker_action = [:disable]
  end

  service 'dbus-broker' do
    action dbus_broker_action
  end

  # For user sessions, only enable dbus-broker if it's the wanted implementation
  link '/etc/systemd/user/dbus.service' do
    to '/usr/lib/systemd/user/dbus-broker.service'
    if wanted_impl == 'dbus-broker'
      action :create
    else
      action :delete
    end
  end

  # If we need to switch dbus implementation and we're allowed to, request a
  # reboot
  if wanted_impl != current_impl
    if node['fb_dbus']['allow_implementation_switch']
      fb_helpers_reboot 'switch dbus implementation' do
        required node['fb_dbus']['reboot_required']
        action :deferred
      end
    else
      Chef::Log.warn(
        "fb_dbus: current dbus implementation is #{current_impl} but" +
        "#{wanted_impl} is desired; reboot to complete the switchover",
      )
    end
  end
end
