#
# Cookbook Name:: fb_kpatch
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
#

if !node.centos? || node.centos7?
  fail 'fb_kpatch is only supported on CentOS 8 or later'
end

package 'kpatch-runtime' do
  only_if { node['fb_kpatch']['manage_packages'] }
  action :upgrade
end

service 'kpatch' do
  only_if { node['fb_kpatch']['enable'] }
  action [:enable, :start]
end

service 'disable kpatch' do
  not_if { node['fb_kpatch']['enable'] }
  service_name 'kpatch'
  action [:stop, :disable]
end

fb_systemd_override 'before-remount-fs' do
  unit_name 'kpatch.service'
  content({
            'Unit' => {
              'DefaultDependencies' => 'no',
              'Before' => 'systemd-remount-fs.service',
            },
          })
end
