#
# Cookbook:: fb_ssh
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

client_pkg = value_for_platform_family(
  ['rhel', 'fedora'] => 'openssh-clients',
  ['debian'] => 'openssh-client',
)

svc = value_for_platform_family(
  ['rhel', 'fedora'] => 'sshd',
  ['debian'] => 'ssh',
)

package client_pkg do
  only_if { node['fb_ssh']['manage_packages'] }
  action :upgrade
end

package 'openssh-server' do
  action :upgrade
  notifies :restart, 'service[ssh]'
end

whyrun_safe_ruby_block 'handle late binding ssh configs' do
  block do
    %w{keys principals}.each do |type|
      enable_name = "enable_central_authorized_#{type}"
      if node['fb_ssh'][enable_name]
        cfgname = "Authorized#{type.capitalize}File"
        if node['fb_ssh']['sshd_config'][cfgname]
          Chef::Log.warn(
            "fb_ssh: Overriding sshd '#{cfgname}' per '#{enable_name}'",
          )
        end
        node.default['fb_ssh']['sshd_config'][cfgname] =
          "#{FB::SSH::DESTDIR[type]}/%u"
      end
    end
  end
end

template '/tmp/sshd_config' do
  source 'ssh_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({ :type => 'sshd_config' })
end

ruby_block 'debug' do
  block do
    puts ::File.read('/tmp/sshd_config')
    s = Mixlib::ShellOut.new('/usr/sbin/sshd -t -f /tmp/sshd_config')
    s.run_command
    puts s.stdout
    puts s.stderr
  end
end

template '/etc/ssh/sshd_config' do
  source 'ssh_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({ :type => 'sshd_config' })
  verify '/usr/sbin/sshd -t -f %{path}'
  notifies :restart, 'service[ssh]'
end

template '/etc/ssh/ssh_config' do
  source 'ssh_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({ :type => 'ssh_config' })
end

fb_ssh_authorization 'manage keys' do
  only_if { node['fb_ssh']['enable_central_authorized_keys'] }
  action :manage_keys
end

fb_ssh_authorization 'manage principals' do
  only_if { node['fb_ssh']['enable_central_authorized_principals'] }
  action :manage_principals
end

service 'ssh' do
  # rather than "service svc", give it a consistent name
  # in case others want to notify it, and then just override
  # the service name internally to the resource
  service_name svc
  action [:enable, :start]
end
