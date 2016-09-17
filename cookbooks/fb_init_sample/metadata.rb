# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
name 'fb_init_sample'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache 2.0'
description 'Setup a base runlist for using Facebook cookbooks'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
%w{
  fb_apt
  fb_cron
  fb_ethers
  fb_fstab
  fb_helpers
  fb_hostconf
  fb_hosts
  fb_limits
  fb_logrotate
  fb_modprobe
  fb_motd
  fb_nsswitch
  fb_swap
  fb_securetty
  fb_sysctl
  fb_syslog
  fb_systemd
}.each do |cb|
  depends cb
end
