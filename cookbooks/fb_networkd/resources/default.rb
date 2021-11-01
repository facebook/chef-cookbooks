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
  network_names = node['fb_networkd']['networks'] ?
    node['fb_networkd']['networks'].keys : []
  netdev_names = node['fb_networkd']['devices'] ?
    node['fb_networkd']['devices'].keys : []
  dup_names = network_names & netdev_names
  if dup_names != []
    fail 'fb_networkd: Conflicting names in network and netdev ' +
         'configurations can lead to unexpected behavior. The following ' +
         'names conflict: ' + dup_names.join(', ').to_s
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

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]", :delayed
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

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, "execute[udevadm trigger #{conf['name']}]", :delayed
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

    fb_helpers_gated_template conffile do # ~FB031
      allow_changes node.interface_change_allowed?(conf['name'])
      source 'networkd.conf.erb'
      owner node.root_user
      group node.root_group
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[networkctl reconfigure #{conf['name']}]", :delayed
    end
  end
end
