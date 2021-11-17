# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

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

  # Both dbus-daemon and dbus-broker rely on the dbus unit being enabled. If
  # we're currently running dbus-daemon and want to continue running it, also
  # ensure it's started
  dbus_action = [:enable]
  if wanted_impl == 'dbus-daemon' && current_impl == 'dbus-daemon'
    dbus_action << :start
  end

  service 'dbus' do
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

  # If we need to switch dbus implementation, request a reboot
  fb_helpers_reboot 'switch dbus implementation' do
    only_if { wanted_impl != current_impl }
    required node['fb_dbus']['reboot_required']
    action :deferred
  end
end
