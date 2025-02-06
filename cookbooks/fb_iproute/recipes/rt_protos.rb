#
# Cookbook Name:: fb_iproute::rt_protos
# Recipe:: default
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

rt_protos_d_dir = '/etc/iproute2/rt_protos.d'.freeze

directory '/etc/iproute2' do
  only_if { node['fb_iproute']['rt_protos_ids'] }
  owner node.root_user
  group node.root_group
  mode '0755'
  action :create
end

directory rt_protos_d_dir do
  only_if { node['fb_iproute']['rt_protos_ids'] }
  owner node.root_user
  group node.root_group
  mode '0755'
  action :create
end

template "#{rt_protos_d_dir}/chef.conf" do
  only_if { node['fb_iproute']['rt_protos_ids'] }
  source 'rt_protos.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
end
