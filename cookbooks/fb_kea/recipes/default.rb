#
# Cookbook:: fb_kea
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
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if fedora_derived?
  pkgs = %w{
    kea
  }
  kea_group = 'kea'
elsif debian?
  pkgs = %w{
    kea
    kea-admin
    kea-ctrl-agent
    kea-dhcp-ddns-server
    kea-dhcp4-server
    kea-dhcp6-server
  }
  kea_group = '_kea'
end

package 'kea packages' do
  only_if { node['fb_kea']['manage_packages'] }
  package_name pkgs
  action :upgrade
end

whyrun_safe_ruby_block 'determine apparmor workaround' do
  only_if { node['fb_kea']['verify_aa_workaround'] == 'auto' }
  block do
    Chef::Log.debug(
      'fb_kea: Determining if we should use the AppArmor workaround',
    )
    # by default, turn it off, then we if we're very sure, we'll turn
    # it on
    node.default['fb_kea']['verify_aa_workaround'] = false
    aastatus = which('aa-status')
    if aastatus
      cmd = [aastatus, '--filter.mode=enforce']
      s = Mixlib::ShellOut.new(cmd).run_command
      aa_enforced = s.stdout.each_line.any? do |line|
        line.include?('kea-dhcp')
      end
      if aa_enforced
        cmd = ['apparmor_parser', '-p', '/etc/apparmor.d/usr.sbin.kea-dhcp4']
        s = Mixlib::ShellOut.new(cmd).run_command
        allowed = s.stdout.each_line.any? do |line|
          line.match?(%r{(/tmp/\.chef-kea.* r,|/tmp/\*\* r,)})
        end
        unless allowed
          Chef::Log.warn(
            'fb_kea: We will briefly disable AppArmor for kea-dhcp{4,6} to' +
            ' run verification on the config files, and then re-enable it.',
          )
          node.default['fb_kea']['verify_aa_workaround'] = true
        end
      end
    end
  end
end

%w{4 6}.each do |fam|
  template "/etc/kea/kea-dhcp#{fam}.conf" do
    only_if { node['fb_kea']["enable_dhcp#{fam}"] }
    source 'kea.conf.erb'
    owner node.root_user
    group node.root_group
    mode '0644'
    variables({ 'type' => fam })
    # Verify does not accept 'lazy', so we must do the work manually
    # in a block. This is slightly annoying as the output is less helpful:
    #   Proposed content for /etc/kea/kea-dhcp4.conf failed verification <Proc>
    # But this allows us to do the aa-work around
    verify { |path| FB::Kea.config_verifier(node, fam, path) }
    notifies :restart, "service[kea-dhcp#{fam}-server]"
  end

  service "kea-dhcp#{fam}-server" do
    only_if { node['fb_kea']["enable_dhcp#{fam}"] }
    action [:enable, :start]
  end

  service "disable kea-dhcp#{fam}-server" do
    not_if { node['fb_kea']['enable_dhcp4'] }
    service_name "kea-dhcp#{fam}-server"
    action [:stop, :disable]
  end
end

template '/etc/kea/kea-dhcp-ddns.conf' do
  only_if { node['fb_kea']['enable_ddns'] }
  owner node.root_user
  group node.root_group
  mode '0644'
  source 'kea.conf.erb'
  variables({ 'type' => 'ddns' })
  verify { |path| FB::Kea.config_verifier(node, 'ddns', path) }
  notifies :restart, 'service[kea-dhcp-ddns-server]'
end

service 'kea-dhcp-ddns-server' do
  only_if { node['fb_kea']['enable_ddns'] }
  action [:enable, :start]
end

service 'disable kea-dhcp-ddns-server' do
  not_if { node['fb_kea']['enable_ddns'] }
  service_name 'kea-dhcp-ddns-server'
  action [:stop, :disable]
end

fb_kea_api_password_file 'doit' do
  only_if do
    # using 'key' here to return an actual bool to prevent chef warnings
    node['fb_kea']['enable_control-agent'] &&
    node['fb_kea']['config']['control-agent']['authentication']['clients-hash'][
      'default'].key?('password-file')
  end
  kea_group kea_group
end

template '/etc/kea/kea-ctrl-agent.conf' do
  only_if { node['fb_kea']['enable_control-agent'] }
  owner node.root_user
  group node.root_group
  mode '0644'
  source 'kea.conf.erb'
  variables({ 'type' => 'control-agent' })
  verify { |path| FB::Kea.config_verifier(node, 'control-agent', path) }
  notifies :restart, 'service[kea-ctrl-agent]'
end

service 'kea-ctrl-agent' do
  only_if { node['fb_kea']['enable_control-agent'] }
  action [:enable, :start]
end

service 'disable kea-ctrl-agent' do
  not_if { node['fb_kea']['enable_control-agent'] }
  service_name 'kea-ctrl-agent'
  action [:stop, :disable]
end
