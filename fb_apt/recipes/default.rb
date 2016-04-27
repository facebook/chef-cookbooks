#
# Cookbook Name:: fb_apt
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.debian? || node.ubuntu?
  fail 'fb_apt is only supported on Debian and Ubuntu.'
end

package 'apt' do
  action :upgrade
end

# This takes precedence over anything in /etc/apt/apt.conf.d. We can't just
# clobber that as several packages will drop configs there.
template '/etc/apt/apt.conf' do
  source 'apt.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[apt-get update]'
end

# No sane package should drop stuff here, and bad preferences can seriously
# mess up a machine, so let's clobber it to be safe.
Dir.glob('/etc/apt/preferences.d/*').each do |f|
  file f do
    action :delete
  end
end

template '/etc/apt/preferences' do
  source 'preferences.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

fb_apt_keys 'process keys' do
  notifies :run, 'execute[apt-get update]'
end

# On Debian nothing should drop things here, but Ubuntu likes to use it for its
# default sources, so we optionally allow keeping its contents
Dir.glob('/etc/apt/sources.list.d/*').each do |f|
  file f do
    not_if { node['fb_apt']['preserve_sources_list_d'] }
    action :delete
  end
end

fb_apt_sources_list 'populate sources list' do
  notifies :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  command 'apt-get update'
  action :nothing
end

# Dummy resource to trigger an update when the package cache goes stale.
log 'periodic package cache update' do
  only_if do
    pkgcache = '/var/cache/apt/pkgcache.bin'
    !::File.exists?(pkgcache) || (
      ::File.exists?(pkgcache) &&
      ::File.mtime(pkgcache) < Time.now - node['fb_apt']['update_delay'])
  end
  notifies :run, 'execute[apt-get update]'
end
