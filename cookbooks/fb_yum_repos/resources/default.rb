# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

default_action :run

action :run do
  YUM_REPOS_D = '/etc/yum.repos.d'.freeze
  repos = node['fb_yum_repos']['repos']

  Dir.glob(::File.join(YUM_REPOS_D, '*.repo')).each do |path|
    entry = ::File.basename(path, '.repo')
    unless repos.keys.include?(entry)
      if node['fb_yum_repos']['preserve_unknown_repos']
        Chef::Log.info(
          "fb_yum_repos[manage repos]: preserving unknown repo at #{path} " +
          'as requested',
        )
      else
        file path do
          action :delete
        end
      end
    end
  end

  repos.each do |group, group_config|
    unless group_config['repos']
      fail 'fb_yum_repos[manage repos]: no repos defined for repo group ' +
           group
    end

    template ::File.join(YUM_REPOS_D, "#{group}.repo") do
      source 'yum.repo.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :group_name => group,
        :group_config => group_config,
      )
    end
  end
end
