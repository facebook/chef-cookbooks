# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
name 'fb_init_sample'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'BSD-3-Clause'
description 'Setup a base runlist for using Facebook cookbooks'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
%w{
  centos
  debian
  ubuntu
}.each do |p|
  supports p
end
%w{
  fb_apt
  fb_apcupsd
  fb_collectd
  fb_cron
  fb_dnsmasq
  fb_dracut
  fb_ebtables
  fb_ethers
  fb_fstab
  fb_grub
  fb_hdparm
  fb_hddtemp
  fb_helpers
  fb_hostconf
  fb_hosts
  fb_ipset
  fb_iptables
  fb_iproute
  fb_limits
  fb_logrotate
  fb_modprobe
  fb_motd
  fb_nsswitch
  fb_postfix
  fb_rpm
  fb_rsync
  fb_swap
  fb_securetty
  fb_sysctl
  fb_syslog
  fb_systemd
  fb_timers
  fb_tmpclean
  fb_vsftpd
}.each do |cb|
  depends cb
end
