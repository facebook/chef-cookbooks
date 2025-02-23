#
# Cookbook:: fb_sasl
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

if fedora_derived?
  packages = %w{cyrus-sasl}
  modules_package_prefix = 'cyrus-sasl'
  sysconfig_path = '/etc/sysconfig/saslauthd'
elsif debian?
  packages = %w{sasl2-bin}
  modules_package_prefix = 'libsasl2-modules'
  sysconfig_path = '/etc/default/saslauthd'
else
  fail "fb_sasl: Unknown platform_family: #{node['platform_family']}"
end

package 'sasl packages' do
  only_if { node['fb_sasl']['manage_packages'] }
  package_name lazy {
    packages + node['fb_sasl']['modules'].map do |mod|
      "#{modules_package_prefix}-#{mod}"
    end
  }
  action :upgrade
  notifies :restart, 'service[saslauthd]'
end

whyrun_safe_ruby_block 'validate config' do
  block do
    node['fb_sasl']['sysconfig'].each_key do |key|
      if key != key.downcase
        fail "fb_sasl: invalid casing for key #{key} - please use downcase"
      end
      if key == 'start'
        fail 'fb_sasl: do not specify "start" in sysconfig, use ' +
          'enable_saslauthd instead'
      end
    end
  end
end

template sysconfig_path do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[saslauthd]'
end

service 'saslauthd' do
  only_if { node['fb_sasl']['enable_saslauthd'] }
  action [:enable, :start]
end

service 'disable saslauthd' do
  not_if { node['fb_sasl']['enable_saslauthd'] }
  service_name 'saslauthd'
  action [:stop, :disable]
end
