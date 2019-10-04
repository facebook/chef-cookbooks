#
# Cookbook Name:: fb_rpm
# Recipe:: packages
#
# Copyright (c) 2017-present, Facebook, Inc.
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
  variables :overrides => {}
  owner 'root'
  group 'root'
  mode '0644'
end
