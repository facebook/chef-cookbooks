# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_logrotate'] = {
  'globals' => {
    'rotate' => '14',
    'maxage' => '14',
    'compresscmd' => '/usr/bin/pigz',
  },
  'configs' => {},
  'add_locking_to_logrotate' => false,
}
