#
# Cookbook Name:: fb_rpm
# Recipe:: default
#
# Copyright (c) 2017-present, Facebook, Inc.
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

unless node.centos?
  fail 'fb_rpm is only supported on CentOS!'
end

include_recipe 'fb_rpm::packages'

directory '/etc/rpm' do
  owner node.root_user
  group node.root_group
  mode '0755'
end

whyrun_safe_ruby_block 'set database backend' do
  block do
    node.default['fb_rpm']['macros']['%_db_backend'] =
      node['fb_rpm']['db_backend']
  end
end

template '/etc/rpm/macros' do
  source 'macros.erb'
  variables :overrides => {}
  owner node.root_user
  group node.root_group
  mode '0644'
end

execute 'convert database format' do
  only_if do
    allow_db_conversion = node['fb_rpm']['allow_db_conversion']
    wanted_backend = node['fb_rpm']['db_backend']
    Chef::Log.debug("fb_rpm: allow_db_conversion is #{allow_db_conversion}")
    if node['rpm'] && node['rpm']['macros'] &&
        !node['rpm']['macros']['_db_backend'].nil?
      current_backend = node['rpm']['macros']['_db_backend']
      Chef::Log.debug("fb_rpm: current backend is #{current_backend}")
      Chef::Log.debug("fb_rpm: wanted backend is #{wanted_backend}")
    elsif allow_db_conversion
      Chef::Log.warn(
        'fb_rpm: cannot find db_backed in ohai, disabling database conversion',
      )
      allow_db_conversion = false
    end

    # Convert if conversion is allowed in the first place
    allow_db_conversion &&
      # Convert if the requested db backend doesn't match the current one,
      # assuming the ohai plugin is available
      ((wanted_backend != current_backend) ||
       # Convert if we want sqlite but there's an ndb package db on disk
       (wanted_backend == 'sqlite' && File.exist?('/var/lib/rpm/Packages.db')))
  end
  command '/bin/rpm --rebuilddb'
end
