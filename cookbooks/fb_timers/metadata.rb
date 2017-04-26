# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
name 'fb_timers'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'BSD-3-Clause'
description 'Installs/Configures Chef-defined Systemd Timers'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# never EVER change this number, ever.
version '0.1.0'
supports 'centos'
supports 'debian'
supports 'ubuntu'
depends 'fb_systemd'
