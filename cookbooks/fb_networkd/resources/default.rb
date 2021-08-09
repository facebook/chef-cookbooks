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
    unless conf['name']
      conf['name'] = name
    end
    unless conf['priority']
      conf['priority'] = FB::Networkd::DEFAULT_NETWORK_PRIORITY
    end
    unless conf['config'] &&
           conf['config']['Match'] &&
           conf['config']['Match']['Name']
      conf['config']['Match']['Name'] = conf['name']
    end

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-#{conf['name']}.network",
    )

    execute "reconfigure #{conf['name']}.network" do
      command "/bin/networkctl reconfigure #{conf['name']}"
      action :nothing
    end

    template conffile do # ~FB031
      source 'networkd.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[reconfigure #{conf['name']}.network]", :delayed
    end
  end

  # TODO figure out the proper thing to restart/reload on link file changes
  node['fb_networkd']['links'].each do |name, defconf|
    conf = defconf.dup
    unless conf['name']
      conf['name'] = name
    end
    unless conf['priority']
      conf['priority'] = FB::Networkd::DEFAULT_LINK_PRIORITY
    end

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-#{conf['name']}.link",
    )

    template conffile do # ~FB031
      source 'networkd.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :config => conf['config'],
      )
    end
  end

  node['fb_networkd']['devices'].each do |name, defconf|
    conf = defconf.dup
    unless conf['name']
      conf['name'] = name
    end
    unless conf['priority']
      conf['priority'] = FB::Networkd::DEFAULT_DEVICE_PRIORITY
    end
    unless conf['config'] &&
           conf['config']['NetDev'] &&
           conf['config']['NetDev']['Name']
      conf['config']['NetDev']['Name'] = conf['name']
    end

    conffile = ::File.join(
      FB::Networkd::BASE_CONFIG_PATH,
      "#{conf['priority']}-#{conf['name']}.netdev",
    )

    execute "reconfigure #{conf['name']}.netdev" do
      command "/bin/networkctl reconfigure #{conf['name']}"
      action :nothing
    end

    template conffile do # ~FB031
      source 'networkd.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :config => conf['config'],
      )
      notifies :run, 'execute[networkctl reload]', :immediately
      notifies :run, "execute[reconfigure #{conf['name']}.netdev]", :delayed
    end
  end
end
