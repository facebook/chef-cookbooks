#
# Cookbook Name:: fb_init_sample
# Recipe:: default
#
# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# SANITY-INDUCING HACK
# If we have never run before, run in debug mode. This ensures that for
# first run/bootstrapping issues we have lots of visibility.
if node.firstboot_any_phase?
  Chef::Log.info('Enabling debug log for first run')
  Chef::Log.level = :debug
end

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
if node.macosx?
  include_recipe 'fb_launchd'
end
include_recipe 'fb_nsswitch'
# HERE: ssh
if node.centos?
  include_recipe 'fb_ldconfig'
end
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
  include_recipe 'fb_sdparm'
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

if node.firstboot_tier?
  include_recipe 'fb_init_sample::firstboot'
end

unless node.centos6?
  include_recipe 'fb_apcupsd'
  # Turn off dnsmasq on sid as it doesn't play well with travis
  if node.debian? && node['platform_version'].include?('sid')
    node.default['fb_dnsmasq']['enable'] = false
  end
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
