#
# Cookbook:: fb_users
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

whyrun_safe_ruby_block 'validate users and groups' do
  block do
    FB::Users._validate(node)
  end
end

ohai 'fb_users reloading ohai->etc' do
  action :nothing
end

fb_users 'converge users and groups' do
  not_if do
    node['fb_users']['users'].empty? && node['fb_users']['groups'].empty?
  end
  notifies :reload, 'ohai[fb_users reloading ohai->etc]', :immediately
end
