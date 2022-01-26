# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Facebook, Inc.
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

default_action :manage

action :manage do
  managed_networks = []
  managed_links = []
  managed_netdevs = []
  config_glob = ::File.join(
    FB::Networkd::BASE_CONFIG_PATH, '*.{network,netdev,link}'
  )
  Dir.glob(config_glob).each do |path|
    if ::File.basename(path).include?('-fb_networkd-')
      if path.end_with?('.network')
        managed_networks << path
      elsif path.end_with?('.link')
        managed_links << path
      elsif path.end_with?('.netdev')
        managed_netdevs << path
      end
    else
      Chef::Log.warn("fb_networkd: Unmanaged network config #{path} found")
    end
  end

  node['fb_networkd']['networks'].each do |name, defconf|
    conf = defconf.dup
    conf['name'] = name

    unless conf['priority']
      if conf['name'] == node['fb_networkd']['primary_interface']
        conf['priority'] =
          FB::Networkd::DEFAULT_PRIMARY_INTERFACE_NETWORK_PRIORITY
      else
        conf['priority'] = FB::Networkd::DEFAULT_NETWORK_PRIORITY
      end
    end
    unless conf['config']
      fail "fb_networkd: Cannot set up network config on #{conf['name']} " +
           "without the 'config' attribute"
    end
    unless conf['config']['Match']
      conf['config']['Match'] = {}
    end
    conf['config']['Match']['Name'] = conf['name']

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-fb_networkd-#{conf['name']}.network",
    )

    # This file is actively managed and already exists on the host so remove it
    # from the "manageds" array.
    remove_conflicts = false
    if managed_networks.include?(conffile)
      managed_networks.delete(conffile)
      remove_conflicts = true
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_networks = managed_networks.grep(
      /-fb_networkd-#{conf['name']}.network$/,
    )
    conflicting_networks ||= []
    conflicting_networks.each do |path|
      managed_networks.delete(path)

      file path do
        only_if do
          node.interface_change_allowed?(conf['name']) && remove_conflicts
        end
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, 'execute[networkctl reload]'
        notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name']) && remove_conflicts
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]'
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
    end
  end

  node['fb_networkd']['links'].each do |name, defconf|
    conf = defconf.dup
    conf['name'] = name

    unless conf['priority']
      if conf['name'] == node['fb_networkd']['primary_interface']
        conf['priority'] = FB::Networkd::DEFAULT_PRIMARY_INTERFACE_LINK_PRIORITY
      else
        conf['priority'] = FB::Networkd::DEFAULT_LINK_PRIORITY
      end
    end
    unless conf['config']
      fail "fb_networkd: Cannot set up link config on #{conf['name']} " +
           "without the 'config' attribute"
    end
    unless conf['config']['Match']
      conf['config']['Match'] = {}
    end
    conf['config']['Match']['OriginalName'] = conf['name']

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-fb_networkd-#{conf['name']}.link",
    )

    # This file is actively managed and already exists on the host so remove it
    # from the "manageds" array.
    remove_conflicts = false
    if managed_links.include?(conffile)
      managed_links.delete(conffile)
      remove_conflicts = true
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_links = managed_links.grep(
      /-fb_networkd-#{conf['name']}.link$/,
    )
    conflicting_links ||= []
    conflicting_links.each do |path|
      managed_links.delete(path)

      file path do
        only_if do
          node.interface_change_allowed?(conf['name']) && remove_conflicts
        end
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, "execute[udevadm trigger #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name']) && remove_conflicts
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, "execute[udevadm trigger #{conf['name']}]"
    end
  end

  node['fb_networkd']['devices'].each do |name, defconf|
    conf = defconf.dup
    conf['name'] = name

    unless conf['priority']
      if conf['name'] == node['fb_networkd']['primary_interface']
        conf['priority'] =
          FB::Networkd::DEFAULT_PRIMARY_INTERFACE_DEVICE_PRIORITY
      else
        conf['priority'] = FB::Networkd::DEFAULT_DEVICE_PRIORITY
      end
    end
    unless conf['config']
      fail "fb_networkd: Cannot set up netdev config on #{conf['name']} " +
           "without the 'config' attribute"
    end
    # Unlike network and link configurations which expect `[Match]` to be filled
    # out, netdev configurations require the `[NetDev]` section's `Name`
    # property.
    unless conf['config']['NetDev']
      conf['config']['NetDev'] = {}
    end
    conf['config']['NetDev']['Name'] = conf['name']

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-fb_networkd-#{conf['name']}.netdev",
    )

    # This file is actively managed and already exists on the host so remove it
    # from the "manageds" array.
    remove_conflicts = false
    if managed_netdevs.include?(conffile)
      managed_netdevs.delete(conffile)
      remove_conflicts = true
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_netdevs = managed_netdevs.grep(
      /-fb_networkd-#{conf['name']}.netdev$/,
    )
    conflicting_netdevs ||= []
    conflicting_netdevs.each do |path|
      managed_netdevs.delete(path)

      file path do
        only_if do
          node.interface_change_allowed?(conf['name']) && remove_conflicts
        end
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, 'execute[networkctl reload]'
        notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name']) && remove_conflicts
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]'
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
    end
  end

  # For each managed file, check if we can make network changes on the
  # inteface. If we can, then take down the interface (except links) and delete
  # the file.
  managed_networks.each do |path|
    iface = path[/-fb_networkd-(.*?).network/m, 1]

    if iface
      execute "networkctl down #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/networkctl down #{iface}"
        ignore_failure true # if the interface was not up, already down, etc.
        action :nothing
      end

      file path do
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[networkctl down #{iface}]"
        notifies :run, 'execute[networkctl reload]'
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  managed_links.each do |path|
    iface = path[/-fb_networkd-(.*?).link/m, 1]

    if iface
      execute "udevadm trigger #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/udevadm trigger --action=add /sys/class/net/#{iface}"
        ignore_failure true # if the device is already down, etc.
        action :nothing
      end

      file path do
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[udevadm trigger #{iface}]"
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  managed_netdevs.each do |path|
    iface = path[/-fb_networkd-(.*?).netdev/m, 1]

    if iface
      execute "networkctl delete #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/networkctl delete #{iface}"
        ignore_failure true # if the interface was not up, already down, etc.
        action :nothing
      end

      file path do
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[networkctl delete #{iface}]"
        notifies :run, 'execute[networkctl reload]'
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end
end
