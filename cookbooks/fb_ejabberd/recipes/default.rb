#
# Cookbook:: fb_ejabberd
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

package 'ejabberd packages' do
  only_if { node['fb_ejabberd']['manage_packages'] }
  package_name lazy {
    ['ejabberd'] + node['fb_ejabberd']['extra_packages']
  }
  action :upgrade
end

template '/etc/ejabberd/ejabberd.yml' do
  owner 'ejabberd'
  group 'ejabberd'
  mode '0640'
  notifies :restart, 'service[ejabberd]'
end

template '/etc/default/ejabberd' do
  source 'sysconfig.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[ejabberd]'
end

service 'ejabberd' do
  # if you try to restart ejabberd, often times epmd will still
  # be holding its port open. If you stop epmd.service (which doesn't
  # stop its socket), and restart ejabberd, that'll start everything
  # up properly
  restart_command '
    systemctl stop ejabberd
    systemctl stop epmd
    systemctl restart ejabberd'
  action [:enable, :start]
end
