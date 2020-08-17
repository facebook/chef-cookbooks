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

default_action :create
property :interface, :is => String, :name_property => true

action_class do
  def build_config
    configs = {}
    bridging = false
    # If someone wants their primary interface to be something other
    # than eth0, then we need to make sure we process that interface...
    primary_int = node['fb_network_scripts']['primary_interface']
    unless node['fb_network_scripts']['interfaces'][primary_int]
      node.default['fb_network_scripts']['interfaces'][primary_int] = {}
    end
    # and also, lets clean up our default, assuming they haven't touched it
    if primary_int != 'eth0' &&
       node['fb_network_scripts']['interfaces']['eth0'] &&
       node['fb_network_scripts']['interfaces']['eth0'].empty?
      node.rm(:fb_network_scripts, :interfaces, :eth0)
    end

    interface_configs = node['fb_network_scripts']['interfaces'].to_hash
    interface_configs.each do |interface, config|
      # Some defaults
      config['name'] = interface
      unless config['onboot']
        config['onboot'] = 'yes'
      end
      unless config['bootproto']
        config['bootproto'] = 'static'
      end
      unless config['v6router']
        config['v6router'] = 'no'
      end
      unless config['ipv6_autoconf']
        config['ipv6_autoconf'] = 'yes'
      end
      # Some sanity checking
      if [false, 'no', 'n', 'N', 'NO'].include?(config['onboot'])
        config['onboot'] = 'no'
      else
        config['onboot'] = 'yes'
      end
      if [true, 'yes', 'y', 'Y', 'YES'].include?(config['v6router'])
        config['v6router'] = 'yes'
      else
        config['v6router'] = 'no'
      end
      Chef::Log.debug("NETCONF: #{interface} #{config}")

      have_v4_config = (config.key?('ip') && config.key?('netmask')) ||
        config.key?('my_inner_ipaddr')
      have_v6_config = config.key?('ipv6')
      want_auto = (config['bootproto'] == 'static' &&
                   !have_v4_config && !have_v6_config)
      if config['range']
        # In the IPv4 world, if we use ranges on tunl0, we set the tunl0
        # interface to 127.0.0.2.
        config['ip'] = '127.0.0.2'
        config['netmask'] = '255.255.255.0'
      elsif want_auto
        if interface == primary_int
          unless config['ip'] || config['ipv6']
            fail "fb_network_scripts: #{interface} has neither IPv4 nor " +
                 'IPv6 address, aborting'
          end
        # If we are a bridge *member* we should not have a boot proto
        elsif config['bridge'] || config['ovs_bridge']
          config.delete('bootproto')
          bridging = true
        else
          # But we don't do that on non-primary interfaces, because otherwise
          Chef::Log.error(
            "fb_network_scripts: you requested that #{interface} be " +
            "configured, but didn't provide configuration data, (and _also_" +
            "it's not the primary interface [#{primary_int}], so it cannot " +
            'be configured!',
          )
          fail 'fb_network_scripts: not enough data to configure ' +
               "#{interface}, cowardly refusing to continue."
        end
      end
      # This is not part of the else-if above because one could have a
      # v6 range *and* other stuff because v6ranges aren't subinterfaces
      # they're just additional addresses.
      if config['v6range']
        # Unlock range files, IPv6 config files can't do ranges, so we
        # take that range syntax and expand it into the full list of IPs
        # and list them out in IPV6SECONDARIES
        unless config['v6secondaries']
          config['v6secondaries'] = []
        end
        config['v6secondaries'] += FB::NetworkScripts.v6range2list(
          config['v6range']['start'], config['v6range']['end']
        )
        unless config['ipv6']
          config['ipv6'] = config['v6secondaries'].shift
        end
      end

      configs[interface] = config
    end

    configs.values
  end
end

# We create a bunch of resources here which people expect to be able to notify,
# so we cannot use notifying_action which will create a subcontext.
#
# Note that for redhat, we will automatically build all the right services
# and notifications, and so we never report that we changed things
action :create do
  configs = build_config

  nodelete = ['lo', node['fb_network_scripts']['primary_interface']]
  primary_int = node['fb_network_scripts']['primary_interface']
  is_v6_enabled = ::File.exist?('/proc/sys/net/ipv6')
  ifup_sysctl = {}

  configs.each do |config|
    iface = config['name']
    nodelete << iface
    is_new_iface = !::File.exist?("/sys/class/net/#{iface}")

    # When we create a bridge for the first time (or when we setup a bridge
    # member interface), setup the config but do not start it. We do this
    # because there's no concept of dependencies between interfaces, and
    # starting a bridge but not his members (or viceversa) will kill the
    # network, which will cause the Chef run to fail. Because the interfaces
    # have been modified, both the bridge and its members will be (re)started
    # together at the end of the Chef run, thus ensuring we don't lose
    # connectivity.
    if (iface.start_with?('br', 'ovsbr') &&
        iface == primary_int && is_new_iface) ||
       (config['bridge'] || config['ovs_bridge'])
      iface_action = [:enable]
    else
      iface_action = [:enable, :start]
    end

    # You'd think we could use net.ipv6.conf.default.* for this, but it
    # doesn't actually work in the bridge scenario, for two reasons:
    # - defaults are applied when the interface node is created, so they won't
    #   affect bridge members (which already exist)
    # - for some reason defaults are completely ignored for bridge interfaces
    # Additionally, for every interface with IPv6 enabled the ifup-ipv6
    # script will helpfully reset these sysctl to whatever it thinks is right
    # -- which is generally not what we want -- on every interface (re)start
    if is_v6_enabled && iface == primary_int
      ifup_sysctl = {
        "net.ipv6.conf.#{iface}.autoconf" => 0,
        "net.ipv6.conf.#{iface}.accept_ra" => 1,
        "net.ipv6.conf.#{iface}.accept_ra_pinfo" => 0,
      }
    elsif is_v6_enabled && (config['bridge'] || config['ovs_bridge'])
      ifup_sysctl = {
        "net.ipv6.conf.#{iface}.disable_ipv6" => 0,
      }
    end
    ifup_sysctl.each do |key, val|
      # These are then consumed by ifup-local.erb which gets executed
      # after interface (re)start. This template is defined in the recipe
      # fb_network_scripts::default and will be processed after this provider.
      node.default['fb_network_scripts']['ifup']['sysctl'][key] = val
    end

    fb_network_scripts_redhat_interface iface do
      config config
      action iface_action
      # S169223 - limiting this to provisioning for now, will roll back out
      # to being enabled everywhere after some mitigations are enacted
      if node.interface_change_allowed?(iface)
        notifies :restart, "fb_network_scripts_redhat_interface[#{iface}]"
      end
    end
  end

  #
  # Delete dangling interfaces
  #
  nodelete.uniq!

  # Walk for interfaces up that we don't know about
  Dir.glob('/sys/class/net/*').each do |path|
    iface = ::File.basename(path)
    unless nodelete.include?(iface)
      operfile = "/sys/class/net/#{iface}/operstate"
      unless ::File.read(operfile).strip == 'down'
        # If it's an eth* interface and we don't know about it, shut it down.
        #
        # In theory we'd do this for all interfaces, but things like proxygen
        # may manage their own virtual interfaces (tunl0, iptnl0, other), so
        # for those we just warn, to be safe.
        if iface.start_with?('eth')
          fb_network_scripts_redhat_interface iface do
            action [:stop, :disable]
          end
        else
          Chef::Log.warn(
            "fb_network_scripts: interface #{iface} running but not Chef " +
            'controlled',
          )
        end
      end
    end
  end

  # Next, anything configured we don't know about
  Dir.glob('/etc/sysconfig/network-scripts/ifcfg-*').each do |path|
    fname = ::File.basename(path)
    iface = fname.split('-')[1..-1].join('-').sub('-range', '')
    next if nodelete.include?(iface)
    fb_network_scripts_redhat_interface iface do
      action [:stop, :disable]
    end
  end
end
