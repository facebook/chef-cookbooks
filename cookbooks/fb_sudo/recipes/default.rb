#
# Cookbook:: fb_sudo
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

package 'sudo' do
  action :upgrade
end

template '/etc/sudoers' do
  source 'sudoers.erb'
  mode '0440'
  owner 'root'
  group 'root'
  verify 'visudo -c -q -f %{path}'
end

directory '/etc/sudoers.d' do
  action :delete
  recursive true
end
