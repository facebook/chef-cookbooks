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
  # There are some situations (i.e. changing the primary interface and
  # corresponding addresses) where we need to restart systemd-networkd to make
  # it happen smoothly. In that case this flag will get set for those situations
  # as long as we are allowed to make network changes.
  restart_networkd = false

  ohai_ifaces = node['network']['interfaces'].to_hash.keys

  # Set up execute resources to reconfigure network settings so that they can be
  # notified by and subscribed to from other recipes.
  interfaces = (node['fb_networkd']['networks'].keys +
                node['fb_networkd']['devices'].keys +
                node['fb_networkd']['links'].keys).uniq
  interfaces.each do |iface|
    next if iface == 'lo'

    execute "networkctl reconfigure #{iface}" do
      command "/bin/networkctl reconfigure #{iface}"
      action :nothing
    end

    # For existing interfaces filled out by the network plugin, the execute
    # block was already set up in the fb_networkd recipe. If we haven't set it
    # up yet, add it here.
    unless ohai_ifaces.include?(iface)
      execute "udevadm trigger #{iface}" do
        command "/bin/udevadm trigger --action=add /sys/class/net/#{iface}"
        action :nothing
      end
    end
  end

  # First collect all the systemd-networkd configuration files on the host. As
  # we parse each interface, items will be removed from each array. By the
  # end of the resource, only unmanaged (e.g. interfaces/files we want to =
  # remove) will remain.
  on_host_networks = []
  on_host_links = []
  on_host_netdevs = []
  config_glob = ::File.join(
    FB::Networkd::BASE_CONFIG_PATH, '*.{network,netdev,link}'
  )
  Dir.glob(config_glob).each do |path|
    if ::File.basename(path).include?('-fb_networkd-')
      if path.end_with?('.network')
        on_host_networks << path
      elsif path.end_with?('.link')
        on_host_links << path
      elsif path.end_with?('.netdev')
        on_host_netdevs << path
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

    # Set up the template for this interface
    fb_helpers_gated_template conffile do
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
    end

    # This file is actively managed and already exists on the host so remove it
    # from the "on_host" array.
    if on_host_networks.include?(conffile)
      on_host_networks.delete(conffile)
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_networks = on_host_networks.grep(
      /-fb_networkd-#{conf['name']}.network$/,
    )
    conflicting_networks ||= []
    conflicting_networks.each do |path|
      # If this interface was formerly a primary interface, toggle the flag to
      # restart systemd-networkd to make the IP address changes go smoothly.
      # This is a bit of a hack but the alternative is to synchronize toggling
      # the interface on/off which seems harder to implement right than a
      # restart (networkctl reload/reconfigure don't seem to do it).
      restart_networkd ||= ::File.basename(path).start_with?('1-fb_networkd-')

      on_host_networks.delete(path)

      file path do
        only_if { node.interface_change_allowed?(conf['name']) }
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, 'execute[networkctl reload]', :immediately
        notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name'])
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
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

    # Set up the template for this interface
    fb_helpers_gated_template conffile do
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

    # Create dropin directory for link config file.
    dropin_dir = conffile + '.d'
    directory dropin_dir do
      action :create
      owner node.root_user
      group node.root_group
      mode '0755'
    end

    # This file is actively managed and already exists on the host so remove it
    # from the "on_host" array.
    if on_host_links.include?(conffile)
      on_host_links.delete(conffile)
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_links = on_host_links.grep(
      /-fb_networkd-#{conf['name']}.link$/,
    )
    conflicting_links ||= []
    conflicting_links.each do |path|
      on_host_links.delete(path)

      file path do
        only_if { node.interface_change_allowed?(conf['name']) }
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, "execute[udevadm trigger #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name'])
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  node['fb_networkd']['devices'].each do |name, defconf|
    restart_for_new_vlan = false
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

    # Set up the template for this interface
    fb_helpers_gated_template conffile do
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]"

      # If we are making a new VLAN, we must restart systemd-networkd for it to
      # be created. Detect this case and set the restart flag.
      if !on_host_networks.include?(conffile) &&
          conf['config']['NetDev']['Kind'] == 'vlan'
        restart_for_new_vlan = true
      end
    end

    # This file is actively managed and already exists on the host so remove it
    # from the "on_host" array.
    if on_host_netdevs.include?(conffile)
      on_host_netdevs.delete(conffile)
    end

    # If this config was previously managed under a different name (e.g.
    # different priority) then set up a file resource to allow it to be deleted
    # when the new config is set up or if the "new" config already exists.
    conflicting_netdevs = on_host_netdevs.grep(
      /-fb_networkd-#{conf['name']}.netdev$/,
    )
    conflicting_netdevs ||= []
    conflicting_netdevs.each do |path|
      on_host_netdevs.delete(path)

      # This was managed under a different file name so don't restart
      # systemd-networkd.
      restart_for_new_vlan = false

      file path do
        only_if { node.interface_change_allowed?(conf['name']) }
        owner node.root_user
        group node.root_group
        mode '0644'
        action :delete
        notifies :run, 'execute[networkctl reload]', :immediately
        notifies :run, "execute[networkctl reconfigure #{conf['name']}]"
      end

      if !node.interface_change_allowed?(conf['name'])
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end

    restart_networkd ||= restart_for_new_vlan
  end

  # For each remaining file, check if we can make network changes on the
  # interface. If we can, then take down the network interface and delete
  # the file.
  on_host_networks.each do |path|
    iface = path[/-fb_networkd-(.*?).network/m, 1]

    if iface
      execute "networkctl down #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/networkctl down #{iface}"
        ignore_failure true # if the interface was not up, already down, etc.
        action :nothing
      end

      file path do # ~FC022
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[networkctl down #{iface}]", :immediately
        notifies :run, 'execute[networkctl reload]'
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  on_host_links.each do |path|
    iface = path[/-fb_networkd-(.*?).link/m, 1]

    if iface
      execute "udevadm trigger #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/udevadm trigger --action=add /sys/class/net/#{iface}"
        ignore_failure true # if the device is already down, etc.
        action :nothing
      end

      file path do # ~FC022
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[udevadm trigger #{iface}]"
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  on_host_netdevs.each do |path|
    iface = path[/-fb_networkd-(.*?).netdev/m, 1]

    if iface
      execute "networkctl delete #{iface}" do
        only_if { node.interface_change_allowed?(iface) }
        command "/bin/networkctl delete #{iface}"
        ignore_failure true # if the interface was not up, already down, etc.
        action :nothing
      end

      file path do # ~FC022
        only_if { node.interface_change_allowed?(iface) }
        action :delete
        notifies :run, "execute[networkctl delete #{iface}]", :immediately
        notifies :run, 'execute[networkctl reload]'
      end

      unless node.interface_change_allowed?(iface)
        FB::Helpers._request_nw_changes_permission(run_context, new_resource)
      end
    end
  end

  execute 'systemd-networkd restart for tricky changes' do
    only_if { restart_networkd && node.nw_changes_allowed? }
    command '/bin/systemctl restart systemd-networkd'
    action :run
  end
end
