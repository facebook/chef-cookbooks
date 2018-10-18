# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

default['fb_init'] = {
  'firstboot_os' => File.exist?('/root/firstboot_os'),
  'firstboot_tier' => File.exist?('/root/firstboot_tier'),
}
