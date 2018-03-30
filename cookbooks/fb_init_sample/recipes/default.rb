#
# Cookbook Name:: fb_init_sample
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#

# this should be first.
include_recipe 'fb_init_sample::site_settings'

if node.centos?
  # HERE: yum
  include_recipe 'fb_rpm'
end
if node.debian? || node.ubuntu?
  include_recipe 'fb_apt'
end
# HERE: chef_client
if node.systemd?
  include_recipe 'fb_systemd'
  include_recipe 'fb_timers'
end
include_recipe 'fb_nsswitch'
# HERE: ssh
if node.linux? && !node.container?
  include_recipe 'fb_grub'
end
if node.centos?
  include_recipe 'fb_dracut'
end
include_recipe 'fb_modprobe'
include_recipe 'fb_securetty'
include_recipe 'fb_hosts'
include_recipe 'fb_ethers'
# HERE: resolv
include_recipe 'fb_limits'
include_recipe 'fb_hostconf'
include_recipe 'fb_sysctl'
# HERE: networking
include_recipe 'fb_syslog'
if node.linux? && !node.container?
  include_recipe 'fb_hdparm'
  include_recipe 'fb_hddtemp'
end
include_recipe 'fb_postfix'
# HERE: nfs
include_recipe 'fb_swap'
# WARNING!
# fb_fstab is one of the most powerful cookbooks in the facebook suite,
# but it requires some setup since it will take full ownership of /etc/fstab
include_recipe 'fb_fstab'
include_recipe 'fb_logrotate'
# HERE: autofs
include_recipe 'fb_tmpclean'
# HERE: sudo
# HERE: ntp
if node.centos? && !node.container?
  node.default['fb_ipset']['auto_cleanup'] = false
  include_recipe 'fb_ebtables'
  include_recipe 'fb_ipset'
  include_recipe 'fb_iptables'
  include_recipe 'fb_iproute'
  include_recipe 'fb_ipset::cleanup'
end
include_recipe 'fb_motd'
unless node.centos6?
  include_recipe 'fb_apcupsd'
  include_recipe 'fb_dnsmasq'
end
include_recipe 'fb_collectd'
include_recipe 'fb_rsync::server'
include_recipe 'fb_vsftpd'

# we recommend you put this as late in the list as possible - it's one of the
# few places where APIs need to use another API directly... other cookbooks
# often want to setup cronjobs at runtime based on user attributes... they can
# do that in a ruby_block or provider if this is at the end of the 'base
# runlist'
include_recipe 'fb_cron'
