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
  ['mac_os_x'] => 'openssh',
  # not used, but keeps the resource compiling
  ['windows'] => 'openssh-client',
)

svc = value_for_platform_family(
  ['rhel', 'fedora'] => 'sshd',
  ['debian'] => 'ssh',
  ['mac_os_x'] => 'sshd',
  ['windows'] => 'sshd',
)

package client_pkg do
  only_if { node['fb_ssh']['manage_packages'] }
  action :upgrade
end

package 'openssh-server' do
  only_if { node['fb_ssh']['manage_packages'] }
  action :upgrade
  notifies :restart, 'service[ssh]'
end

whyrun_safe_ruby_block 'handle late binding ssh configs' do
  not_if { node.windows? }
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
          File.join(FB::SSH.confdir(node), FB::SSH::DESTDIR[type], '%u')
      end
    end
  end
end

directory FB::SSH.confdir(node) do
  if node.windows?
    rights :full_control, 'Administrators'
    rights :read_execute, ['Administrators', 'Authenticated Users']
  else
    owner 'root'
    group node.root_group
    mode '0755'
  end
end

# sshd won't start if the private keys are too readable.
Dir.glob(::File.join(FB::SSH.confdir(node), '*key')).each do |f|
  file f do
    if node.windows?
      rights :full_control, 'Administrators'
      rights :full_control, 'SYSTEM'
      inherits false
    else
      owner 'root'
      group node.root_group
      mode '0600'
    end
  end
end

template ::File.join(FB::SSH.confdir(node), 'sshd_config') do
  source 'ssh_config.erb'
  unless node.windows?
    owner 'root'
    group node.root_group
    mode '0644'
    if node.windows?
      verify '"C:/Program Files/OpenSSH-Win64/sshd.exe" -t -f %{path}'
    else
      verify '/usr/sbin/sshd -t -f %{path}'
    end
  end
  variables({ :type => 'sshd_config' })
  # in firstboot we may not be able to get in until ssh is restarted
  # on the desired config, so restart immediately. Otherwise, delay
  ntype = node.firstboot_any_phase? ? :immediately : :delayed
  notifies :restart, 'service[ssh]', ntype
end

template ::File.join(FB::SSH.confdir(node), 'ssh_config') do
  source 'ssh_config.erb'
  unless node.windows?
    owner 'root'
    group node.root_group
    mode '0644'
  end
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
  if node['platform'] == 'mac_os_x'
    # On OS X, we must specify the plist to get the right launchd service label.
    plist '/System/Library/LaunchDaemons/ssh.plist'
  end
  action [:enable, :start]
end

if node.windows?
  service 'ssh-agent' do
    action [:enable, :start]
  end
end
