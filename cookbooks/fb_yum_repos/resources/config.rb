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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
property :path, String, :name_property => true
property :config, Hash, :required => true
property :repos, Hash, :required => true

default_action :create

action :create do
  template new_resource.path do # rubocop:disable Chef/Meta/AvoidCookbookProperty
    cookbook 'fb_yum_repos'
    source 'yum.conf.erb'
    owner node.root_user
    group node.root_group
    mode '0644'
    variables(
      :config => new_resource.config,
      :repos => new_resource.repos,
    )
  end
end
