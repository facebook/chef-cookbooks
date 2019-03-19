#
# Cookbook Name:: fb_rpm
# Recipe:: packages
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

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
  rpm-plugin-systemd-inhibit
}

# If you use our backports of rawhide RPM, you also need this,
# but it's not available in C7 stock.
if node.centos7?
  rpm_packages << 'rpm-python'

  yc = Chef::Provider::Package::Yum::YumCache.instance
  if yc.package_available?('rpm-plugin-selinux')
    rpm_packages << 'rpm-plugin-selinux'
  end
else
  rpm_packages += %w{
    python3-rpm
    rpm-plugin-selinux
  }
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
