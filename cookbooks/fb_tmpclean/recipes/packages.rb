#
# Cookbook Name:: fb_tmpclean
# Recipe:: packages
#
# Copyright (c) Facebook, Inc. and its affiliates.
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

case node['platform_family']
when 'rhel', 'fedora'
  pkg = 'tmpwatch'
when 'debian'
  pkg = 'tmpreaper'
when 'mac_os_x'
  pkg = 'tmpreaper'
else
  fail "Unsupported platform_family #{node['platform_family']}, cannot" +
    'continue'
end

package pkg do
  only_if { node['fb_tmpclean']['manage_packages'] }
  action :upgrade
end
