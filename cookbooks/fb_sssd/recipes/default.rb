#
# Cookbook:: fb_sssd
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

packages = %w{
  sssd
  sssd-ad
  sssd-common
  sssd-dbus
  sssd-ipa
  sssd-krb5
  sssd-krb5-common
  sssd-ldap
  sssd-proxy
  sssd-tools
}

extra_packages = value_for_platform_family(
  ['fedora', 'rhel'] => ['sssd-client'],
  ['debian'] => ['sssd-ad-common'],
)

packages += extra_packages

package packages do
  only_if { node['fb_sssd']['enable'] && node['fb_sssd']['manage_packages'] }
  action :upgrade
end

package 'remove sssd' do
  not_if { node['fb_sssd']['enable'] }
  package_name packages
  action :remove
end

template '/etc/sssd/sssd.conf' do
  only_if { node['fb_sssd']['enable'] }
  owner 'root'
  group 'root'
  mode '0600'
  notifies :restart, 'service[sssd]'
end

file '/etc/sssd/sssd.conf' do
  not_if { node['fb_sssd']['enable'] }
  action :delete
end

Dir.glob('/etc/sssd/conf.d/*').each do |f|
  file f do
    only_if { node['fb_sssd']['enable'] }
    action :delete
  end
end

service 'sssd' do
  only_if { node['fb_sssd']['enable'] }
  action [:enable, :start]
  # nsswitch is before sssd (for good reasons), but that means on first
  # boot, we'll trigger on the nsswitch notification and try to restart
  # even when we can't. This could of course happen outside of firstboot
  # so if the binary isn't there at compile time, don't bother setting up
  # the notification. This is safe: if the binary isn't there, it can't
  # be running and therefore can't have an old config... it will then be
  # started by this resource
  if File.exist?('/usr/sbin/sssd')
    subscribes :restart, 'template[/etc/nsswitch.conf]', :immediately
  end
end

service 'disable sssd' do
  not_if { node['fb_sssd']['enable'] }
  # once the package is removed, this fails, sadly
  only_if { ::File.exist?('/lib/systemd/system/sssd.service') }
  service_name 'sssd'
  action [:stop, :disable]
end
