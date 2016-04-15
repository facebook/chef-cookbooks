# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_systemd'] = {
  'default_target' => '/lib/systemd/system/multi-user.target',
  'modules' => [],
  'system' => {},
  'journald' => {
    'Storage' => 'auto',
  },
  'logind' => {
    'enable' => true,
  },
  'tmpfiles' => {
    '/dev/log' => {
      'type' => 'L+',
      'argument' => '/run/systemd/journal/dev-log',
    },
    '/dev/initctl' => {
      'type' => 'L+',
      'argument' => '/run/systemd/initctl/fifo',
    },
  },
  'preset' => {},
  'manage_systemd_packages' => true,
}
