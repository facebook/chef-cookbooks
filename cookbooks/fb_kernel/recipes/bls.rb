#
# Cookbook Name:: fb_kernel
# Recipe:: bls
#
# Copyright (c) 2020-present, Facebook, Inc.
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

directory 'loader' do
  only_if { node['fb_kernel']['manage_bls_configs'] }
  path lazy { File.join(node['fb_kernel']['boot_path'], 'loader') }
  owner node.root_user
  group node.root_group
  mode '0755'
end

directory 'loader/entries' do
  only_if { node['fb_kernel']['manage_bls_configs'] }
  path lazy { File.join(node['fb_kernel']['boot_path'], 'loader', 'entries') }
  owner node.root_user
  group node.root_group
  mode '0755'
end

fb_kernel_bls_entries 'manage bls entries' do
  only_if do
    node['fb_kernel']['manage_bls_configs'] &&
      !node['fb_kernel']['kernels'].empty?
  end
end
