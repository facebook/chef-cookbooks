# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_dbus'] = {
  'implementation' => 'dbus-daemon',
  'manage_packages' => true,
  'reboot_required' => true,
}
