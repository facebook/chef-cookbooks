#
# Cookbook Name:: fb_reprepro
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
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

unless node
  fail 'fb_reprepro is only supported on Debian and Ubuntu.'
end

package 'reprepro' do
  action :upgrade
end

directory 'repository' do
  only_if { node['fb_reprepro']['options']['basedir'] }
  path lazy { node['fb_reprepro']['options']['basedir'] }
  owner lazy { node['fb_reprepro']['user'] }
  group lazy { node['fb_reprepro']['group'] }
  mode '0644'
end

directory 'repository/conf' do
  only_if { node['fb_reprepro']['options']['basedir'] }
  path lazy { "#{node['fb_reprepro']['options']['basedir']}/conf" }
  owner lazy { node['fb_reprepro']['user'] }
  group lazy { node['fb_reprepro']['group'] }
  mode '0644'
end

%w{
  IncomingDir
  TempDir
}.each do |dir|
  directory "repository/#{dir}" do
    only_if do
      node['fb_reprepro']['options']['basedir'] &&
        node['fb_reprepro']['incoming'][dir]
    end
    path lazy do
      "#{node['fb_reprepro']['options']['basedir']}/" +
        node['fb_reprepro']['incoming'][dir]
    end
    owner lazy { node['fb_reprepro']['user'] }
    group lazy { node['fb_reprepro']['group'] }
    mode '0644'
  end
end

%w{
  distributions
  updates
  pulls
  incoming
}.each do |conffile|
  template "repository/conf/#{conffile}" do
    only_if do
      node['fb_reprepro']['options']['basedir'] &&
        node['fb_reprepro'][conffile]
    end
    path lazy do
      "#{node['fb_reprepro']['options']['basedir']}/conf/#{conffile}"
    end
    source 'config.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      :config => conffile,
    )
  end
end

template 'repository/conf/options' do
  only_if { node['fb_reprepro']['options']['basedir'] }
  path lazy do
    "#{node['fb_reprepro']['options']['basedir']}/conf/options"
  end
  source 'options.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
