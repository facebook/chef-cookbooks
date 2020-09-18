# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

default_action :nothing
property :interface, :kind_of => String, :name_attribute => true
property :config, :kind_of => Hash

# for internal use
property :running, :kind_of => [TrueClass, FalseClass]
property :path, :kind_of => String

def whyrun_supported?
  true
end

# This one is here for `load_current_value`
class Helpers
  extend ::FB::NetworkScripts::RHInterfaceHelpers
end

# This one is here for all the actions
action_class do
  class Helpers
    extend ::FB::NetworkScripts::RHInterfaceHelpers
  end
end

load_current_value do |new_resource|
  running Helpers.running?(new_resource.interface, node)
end

# This can shellout because it's called within `converge_by`
def start(interface, best_effort)
  s = Mixlib::ShellOut.new("/sbin/ifup #{interface}").run_command
  unless best_effort
    s.error!
  end
end

# This can shellout because it's called within `converge_by`
def stop(interface)
  # handle the case where we have an up interface without a config file
  if ::File.exist?("/etc/sysconfig/network-scripts/ifcfg-#{interface}")
    cmd = "/sbin/ifdown #{interface}"
  else
    cmd = "/sbin/ifconfig #{interface} down"
  end
  s = Mixlib::ShellOut.new(cmd).run_command
  s.error!
end

# We must track our changes, which means we must run
# things manually, which means we need the queue_restart() hack in
# Fb::Networking::RHInterfaceHelpers.
action :enable do # ~FC017
  requires_full_restart = false
  to_converge = []
  interface = new_resource.interface
  config = new_resource.config

  ifcfg_file = "/etc/sysconfig/network-scripts/ifcfg-#{interface}"
  hwaddr = Helpers.get_hwaddr(interface)
  config_hwaddr = config['hwaddr']
  if config_hwaddr
    unless hwaddr
      fail "fb_network_scripts: no hwaddr found for #{interface} on the " +
        'running system, cannot set explicity configured hwaddr ' +
        "(#{config_hwaddr})"
    end
    # MAC addresses, like IPv6 are hexadecimal based. Unlike IPv6
    # there is no compression (removing zeros). There are a number
    # of formats:
    # (1) 01:23:45:67:89:ab (most common, in Linux)
    # (2) 01-23-45-67-89-ab (rfc7043 EUI48 RR)
    # (3) 0123:4567:89ab (Cisco, et al.)
    # We expect and only support format (1)
    # Differences in case (of hexadecimal characters) is ignored.
    if hwaddr.casecmp(config_hwaddr) != 0
      fail 'fb_network_scripts: Explicitly configured hwaddr ' +
        "(#{config_hwaddr}) does not match running system (#{hwaddr})"
    end
  end
  primary_int = node['fb_network_scripts']['primary_interface']
  routing_config = node['fb_network_scripts']['routing'].to_hash
  # Hack to prevent issues like #8540745
  if ::File.exist?('/etc/sysconfig/network-scripts/ifcfg-br0') &&
     primary_int != 'br0'
    fail 'fb_network_scripts: It looks like you\'re trying to go back from ' +
         'a bridged primary interface. This will require a full networking ' +
         'restart, and possibly a reboot to recover. If you want to ' +
         'proceed, delete /etc/sysconfig/network-scripts/ifcfg-br0 and run ' +
         'Chef again.'
  end

  # There is an ifconfig resource in chef, but it doesn't handle
  # ipv6, or ranges, so we don't use it
  tmp_ifcfg_file = ::File.join(
    Chef::Config[:file_cache_path],
    ::File.basename(ifcfg_file),
  )
  # build resource gives you a resource that's not in the resource collection
  # this is important in this case as we don't want this resource to count
  # towards whether or not WE notify.
  t = build_resource(:template, tmp_ifcfg_file) do
    owner 'root'
    group 'root'
    mode '0644'
    source 'ifcfg.erb'
    variables({
                'interface' => interface,
                'config' => config,
                'hwaddr' => hwaddr,
                'routing_config' => routing_config,
              })
    action :nothing
  end
  t.run_action(:create)

  # this logic isn't conditional on tmp_ifcfg_file updating, because it's not
  # a source of truth... if someone fucks with the real ifcfg_file, we want to
  # catch that.
  updated_keys = ['all']
  if ::File.exist?(ifcfg_file)
    current_file = Helpers.read_ifcfg(ifcfg_file)
    new_file = Helpers.read_ifcfg(tmp_ifcfg_file)
    updated_keys = Helpers.get_changed_keys(current_file, new_file)
  end

  unless updated_keys.empty?
    updated_keys.each do |key|
      case key
      when 'IPV6_SET_SYSCTLS'
        # We treat IPV6_SET_SYSCTL as a no-op while we roll it out, it only
        # affects the up/down and not running state
        next
      when 'IPV6ADDR_SECONDARIES'
        to_converge << :ips
      when 'MTU'
        to_converge << :mtu
      else
        Chef::Log.debug(
          "fb_network_scripts[#{interface}]: #{key} changed, will need " +
          'interface restart',
        )
        # not something we know how to change nicely
        requires_full_restart = true
      end
    end
  end

  # So in the event we entered the above conditional, we need to make sure
  # we update the ifcfg file. However, since `get_changed_keys` intelligently
  # checks for non-meaningful changes such as ip6 addr case changes, we *also*
  # need to see if the file itself changed, even if there is no meaninful change
  # needed, and update the file.
  if !updated_keys.empty? || current_file != new_file
    if node.interface_change_allowed?(interface) || !requires_full_restart
      # Options for updating the file:
      #   * make a new resource for this. Updates will cause two resources to
      #     fire but that's not too terrible
      #   * move the file. Clean except the *next* run will update the temp
      #     file which may confuse people
      #   * copy the file. This isn't atomic, so we actually need to copy to
      #     /tmp and them move it. Code is slightly uglier, but it's the
      #     cleanest end-user experience

      # Tempfile expects the resource passed in to have a `path` method
      # that returns the file we eventually plan to make
      new_resource.path = ifcfg_file
      tempfile =
        Chef::FileContentManagement::Tempfile.new(new_resource).tempfile
      tpath = tempfile.path
      tempfile.close
      FileUtils.copy(tmp_ifcfg_file, tpath)
      ::File.rename(tpath, ifcfg_file)
    else
      Chef::Log.info(
        "fb_network_scripts[#{interface}]: not allowed to change " +
        ifcfg_file.to_s,
      )
      Chef::Log.info(
        "fb_network_scripts[#{interface}]: requesting nw change permission",
      )
      Helpers.request_nw_changes_permission(run_context, new_resource)
    end
  end

  # This enforces ownership and permissions, not content so we can ensure that
  # other users are able to read the ifcfg-* files when needed. See T22854783
  # we use build_resource because we don't want to trigger a restart just
  # because we fix permissions
  t = build_resource(:file, ifcfg_file) do
    only_if { node.interface_change_allowed?(interface) }
    owner 'root'
    group 'root'
    mode '0644'
    action :nothing
  end
  t.run_action(:create)

  t = template "#{ifcfg_file}-range" do
    owner 'root'
    group 'root'
    mode '0644'
    source 'ifcfg-range.erb'
    variables({
                'interface' => interface,
                'config' => config,
              })
    action :nothing
  end
  t.run_action(config['range'] ? :create : :delete)

  if interface == primary_int
    route_key = 'extra_routes'
  else
    route_key = "extra_routes_#{interface}"
  end
  route_config = node['fb_network_scripts']['routing'][route_key]
  if route_config
    extra_routes = route_config.to_hash
  else
    extra_routes = {}
  end
  unless extra_routes.empty?
    route_file = "/etc/sysconfig/network-scripts/route-#{interface}"
    route6_file = "/etc/sysconfig/network-scripts/route6-#{interface}"
    v4_routes = extra_routes.reject { |k, _v| k.include?(':') }
    v6_routes = extra_routes.select { |k, _v| k.include?(':') }
    fb_network_scripts_gated_template route_file do
      owner 'root'
      group 'root'
      mode '0644'
      source 'route.erb'
      variables({
                  'routes' => v4_routes,
                  'config' => config,
                })
      gated_action v4_routes.empty? ? :delete : :create
    end

    fb_network_scripts_gated_template route6_file do
      owner 'root'
      group 'root'
      mode '0644'
      source 'route.erb'
      variables({
                  'routes' => v6_routes,
                  'config' => config,
                })
      gated_action v6_routes.empty? ? :delete : :create
    end
  end

  # We enqueue all the actions here that are "gently massaging" things without
  # a full restart. That's OK, because even if we end up enqueueing a restart,
  # these actions all check for that first.
  to_converge.each do |key|
    case key
    when :ips
      Helpers.queue_update_ips(run_context, new_resource)
    when :mtu
      Helpers.queue_update_mtu(run_context, new_resource)
    end
  end

  # In the event that our magic was not good enough, ensure that things get
  # restarted
  if requires_full_restart
    if node.interface_change_allowed?(interface)
      Chef::Log.warn(
        "fb_network_scripts[#{interface}]: full network interface restart " +
        'required',
      )
      updated_by_last_action true
    end
  end
end

action :update_ips do # ~FC017
  interface = new_resource.interface
  if Helpers.will_restart_network?(run_context)
    Chef::Log.info("Ignoring #{interface} update_ips, network restart queued")
  else
    converge_by("update IPs on #{new_resource}") do
      config = new_resource.config
      Chef::Log.info("New resource #{config}")
      to_add, to_remove = Helpers.get_v6_changes(node, interface, config)
      Chef::Log.debug(
        "fb_network_scripts_redhat_interface[#{interface}] updating IPs: " +
          "#{to_add.size} to add and #{to_remove.size} to remove",
      )
      unless to_add.empty?
        Helpers.add_v6addrs(interface, to_add)
        Chef::Log.info(
          "fb_network_scripts_redhat_interface[#{interface}] Added IPs: " +
            to_add.to_a.to_s,
        )
      end
      unless to_remove.empty?
        Helpers.remove_v6addrs(interface, to_remove)
        Chef::Log.info(
          "fb_network_scripts_redhat_interface[#{interface}] Removed IPs: " +
            to_remove.to_a.to_s,
        )
      end
    end
  end
end

action :update_mtu do
  interface = new_resource.interface
  if Helpers.will_restart_network?(run_context)
    Chef::Log.info("Ignoring #{interface} update_mtu, network restart queued")
  else
    converge_by("update MTU on #{new_resource}") do
      mtu = new_resource.config['mtu'] || 1500
      Helpers.set_mtu(interface, mtu)
      Chef::Log.info(
        "fb_network_scripts_redhat_interface[#{interface}] set mtu to #{mtu}",
      )
    end
  end
end

action :start do
  interface = new_resource.interface
  if Helpers.will_restart_network?(run_context)
    Chef::Log.info("Ignoring #{interface} start, network restart queued")
  elsif current_resource.running
    Chef::Log.debug("#{interface} already up")
  elsif node.interface_start_allowed?(interface)
    converge_by("start #{new_resource}") do
      start(interface, new_resource.config.fetch('best_effort', false))
      Chef::Log.info(
        "fb_network_scripts_redhat_interface[#{interface}] started",
      )
    end
  else
    Chef::Log.info(
      "fb_network_scripts[#{interface}]: not allowed to start #{interface}",
    )
    Chef::Log.info(
      "fb_network_scripts[#{interface}]: requesting nw change permission",
    )
    Helpers.request_nw_changes_permission(run_context, new_resource)
  end
end

action :stop do
  interface = new_resource.interface
  if Helpers.will_restart_network?(run_context)
    Chef::Log.info("Ignoring #{interface} stop, network restart queued")
  elsif !current_resource.running
    Chef::Log.debug("#{interface} already down")
  elsif node.interface_change_allowed?(interface)
    converge_by("stop #{new_resource}") do
      stop(interface)
      Chef::Log.info("fb_network_scripts_redhat_interface[#{interface}] stop")
    end
  else
    Chef::Log.info("fb_network_scripts[#{interface}]: not allowed to stop " +
                      interface.to_s)
    Chef::Log.info("fb_network_scripts[#{interface}]: requesting nw change " +
                      'permission')
    Helpers.request_nw_changes_permission(run_context, new_resource)
  end
end

action :restart do
  interface = new_resource.interface
  if Helpers.will_restart_network?(run_context)
    Chef::Log.info("Ignoring #{interface} restart, network restart queued")
  else
    converge_by("restart #{new_resource}") do
      if current_resource.running
        stop(interface)
      end
      start(interface, new_resource.config.fetch('best_effort', false))
      Chef::Log.info(
        "fb_network_scripts_redhat_interface[#{interface}] restarted",
      )
    end
  end
end

action :disable do
  interface = new_resource.interface
  if node.interface_change_allowed?(interface)
    basefile = "/etc/sysconfig/network-scripts/ifcfg-#{interface}"
    [basefile, "#{basefile}-range"].each do |fname|
      file fname do
        action :delete
      end
    end
  else
    Chef::Log.info(
      "fb_network_scripts[#{interface}]: not allowed to disable #{interface}",
    )
    Chef::Log.info(
      "fb_network_scripts[#{interface}]: requesting nw change permission",
    )
    Helpers.request_nw_changes_permission(run_context, new_resource)
  end
end
