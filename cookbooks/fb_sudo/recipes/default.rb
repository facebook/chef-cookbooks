#
# Cookbook:: fb_sudo
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

include_recipe 'fb_sudo::packages'

template '/etc/sudoers' do
  source 'sudoers.erb'
  mode '0440'
  owner node.root_user
  # https://github.com/chef/cookstyle/issues/657
  # rubocop:disable Lint/UnneededCopDisableDirective
  # rubocop:disable ChefDeprecations/NodeMethodsInsteadofAttributes
  group node.root_group
  # rubocop:enable ChefDeprecations/NodeMethodsInsteadofAttributes
  # rubocop:enable Lint/UnneededCopDisableDirective
  verify 'visudo -c -q -f %{path}'
end

whyrun_safe_ruby_block 'validate sudoers configuration' do
  only_if { node.macos? }
  block do
    %w{root %admin}.each do |user|
      if !node['fb_sudo']['users'][user] ||
       !node['fb_sudo']['users'][user].value?('ALL=(ALL) ALL')
        fail "fb_sudo: missing mandatory rule to grant #{user} access"
      end
    end
  end
end

directory '/etc/sudoers.d' do
  action :delete
  recursive true
end
