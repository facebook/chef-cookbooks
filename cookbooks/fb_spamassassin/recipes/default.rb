#
# Cookbook:: fb_spamassassin
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
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

if node.ubuntu_max_version?(22) || node.debian_max_version?(11)
  Chef::Log.warn('fb_spamassassin only works on OSes that have moved to spamd')
  return
end

packages = value_for_platform_family(
  ['rhel', 'fedora'] => %w{spamassassin},
  ['debian'] => %w{
    sa-compile
    spamassassin
    spamc
    spamd
    fuzzyocr
  },
)

package 'spamassassin packages' do
  package_name packages
  action :upgrade
  notifies :restart, 'service[spamd]'
end

sa_sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/sysconfig/sa-update',
  ['debian'] => '/etc/default/spamassassin',
)

spamd_sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/sysconfig/spamassassin',
  ['debian'] => '/etc/default/spamd',
)

config_dir = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/mail/spamassassin',
  ['debian'] => '/etc/spamassassin',
)

update_job = value_for_platform_family(
  ['rhel', 'fedora'] => 'sa-update',
  ['debian'] => 'spamassassin-maintenance',
)

service_name = value_for_platform_family(
  ['rhel', 'fedora'] => 'spamassassin',
  ['debian'] => 'spamd',
)

whyrun_safe_ruby_block 'late-binding sysconfig variables' do
  block do
    next unless node['fb_spamassassin']['enable_update_job']

    if ['rhel', 'fedora'].include?(node['platform_family'])
      node.default['fb_spamassassin']['sa_sysconfig']['saupdate'] = 'yes'
    elsif ['debian'].include?(node['platform_family'])
      node.default['fb_spamassassin']['sa_sysconfig']['cron'] = '1'
    end
  end
end

template spamd_sysconfig do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  variables({ :flavor => :spamd })
  notifies :restart, 'service[spamd]'
end

template sa_sysconfig do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  variables({ :flavor => :sa })
end

template "#{config_dir}/local.cf" do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[spamd]'
  verify 'spamassassin --lint'
end

template "#{config_dir}/init.pre" do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[spamd]'
end

fb_spamassassin_clean_pre_files 'doit' do
  not_if { node['fb_spamassassin']['preserve_os_pre_files'] }
  configdir config_dir
  notifies :restart, 'service[spamd]'
end

systemd_unit 'enable spam assassin update job' do
  only_if { node['fb_spamassassin']['enable_update_job'] }
  unit_name "#{update_job}.timer"
  action [:enable, :start]
end

systemd_unit 'disable spam assassin update job' do
  not_if { node['fb_spamassassin']['enable_update_job'] }
  unit_name "#{update_job}.timer"
  action [:stop, :disable]
end

service 'spamd' do
  service_name service_name
  action [:enable, :start]
end
