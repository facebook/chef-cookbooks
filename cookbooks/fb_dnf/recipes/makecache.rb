# (c) Meta Platforms, Inc. and its affiliates. Confidential and proprietary.
#
# Cookbook Name:: fb_dnf
# Recipe:: makecache

MAKECACHE_SYSTEMD_UNIT_NAME = 'dnf-makecache.timer'.freeze

if node['fb_dnf']['disable_makecache_timer'] && node['fb_dnf']['enable_makecache_timer']
  Chef::Log.error(
    '[fb_dnf] Something has set BOTH disable + enable makecache timer - Nothing will happen!',
  )
end

# If API is set to true, stop + disable the timer
systemd_unit MAKECACHE_SYSTEMD_UNIT_NAME do
  only_if { node['fb_dnf']['disable_makecache_timer'] }
  not_if { node['fb_dnf']['enable_makecache_timer'] }
  action [:stop, :disable]
end

# If API is set to false, start + enable the timer
systemd_unit MAKECACHE_SYSTEMD_UNIT_NAME do
  only_if { node['fb_dnf']['enable_makecache_timer'] }
  not_if { node['fb_dnf']['disable_makecache_timer'] }
  action [:start, :enable]
end
