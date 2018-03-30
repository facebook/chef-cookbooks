#
# Cookbook Name:: fb_rpm
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.centos?
  fail 'fb_rpm is only supported on CentOS!'
end

if node.centos6?
  package "rpm.#{node['kernel']['machine']}" do
    only_if { node['fb_rpm']['manage_packages'] }
    action :upgrade
  end

  return
end

rpm_packages = %w{
  rpm
  rpm-build-libs
  rpm-libs
  rpm-python
  rpm-plugin-systemd-inhibit
}

# If you use our backports of rawhide RPM, you also need this,
# but it's not available in C7 stock.
yc = Chef::Provider::Package::Yum::YumCache.instance
if yc.package_available?('rpm-plugin-selinux')
  rpm_packages << 'rpm-plugin-selinux'
end

package rpm_packages do
  only_if { node['fb_rpm']['manage_packages'] }
  action :upgrade
end

package 'rpmbuild dependencies' do
  only_if { node['fb_rpm']['rpmbuild'] }
  package_name %w{perl-srpm-macros redhat-rpm-config}
  action :upgrade
end

package 'rpmbuild packages' do
  only_if { node['fb_rpm']['rpmbuild'] && node['fb_rpm']['manage_packages'] }
  package_name %w{rpm-build rpm-sign}
  action :upgrade
end

directory '/etc/rpm' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/rpm/macros' do
  source 'macros.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
