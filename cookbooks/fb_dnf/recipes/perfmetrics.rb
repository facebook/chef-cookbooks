#
# Cookbook Name:: fb_dnf
# Recipe:: perfmetrics
#
# Copyright (c) 2024-present, Facebook, Inc.
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

package 'python3-dnf-plugin-perfmetrics' do
  only_if { node['fb_dnf']['perfmetrics'] }
  action :upgrade
end

config = '/etc/dnf/plugins/perfmetrics.conf'

directory '/var/log/dnf' do
  only_if { node['fb_dnf']['perfmetrics'] }
  owner node.root_user
  group node.root_group
  mode '0755'
end

template config do
  only_if { node['fb_dnf']['perfmetrics'] }
  source 'perfmetrics.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
end

file config do
  not_if { node['fb_dnf']['perfmetrics'] }
  action :delete
end
