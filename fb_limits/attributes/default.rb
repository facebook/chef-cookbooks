# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_limits']['root'] = {
  'nofile' => {
    'hard' => '65535',
    'soft' => '65535',
  },
}

# Only set limit on centos6 as centos5 has a very high default limit already.
# CentOS 6 defaults to 1024
if node.centos6?
  default['fb_limits']['*'] = {
    'nproc' => {
      'hard' => '61278',
      'soft' => '61278',
    },
  }
end
