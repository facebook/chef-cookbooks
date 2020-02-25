# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_less
# Recipe:: default
#
# Copyright (c) 2019-present, Facebook, Inc.
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

package 'less' do
  only_if { node.linux? && node['fb_less']['manage_packages'] }
  action :upgrade
end

cookbook_file '/usr/local/bin/lesspipe.sh' do
  source 'lesspipe.sh'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/etc/profile.d/fbless.sh' do
  source 'profile.d/fbless.sh'
  owner 'root'
  group 'root'
  mode '0644'
end
