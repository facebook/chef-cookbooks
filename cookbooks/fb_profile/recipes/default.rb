#
# Cookbook:: fb_profile
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
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
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#

unless node.linux? || node.macos?
  fail 'fb_profile: this cookbook only supports Linux and MacOS!'
end

directory '/etc/profile.d' do
  owner node.root_user
  # https://github.com/chef/cookstyle/issues/657
  # rubocop:disable Lint/UnneededCopDisableDirective
  # rubocop:disable ChefDeprecations/NodeMethodsInsteadofAttributes
  group node.root_group
  # rubocop:enable ChefDeprecations/NodeMethodsInsteadofAttributes
  # rubocop:enable Lint/UnneededCopDisableDirective
  mode '0755'
end

template '/etc/profile.d/fb_profile.sh' do
  owner node.root_user
  # https://github.com/chef/cookstyle/issues/657
  # rubocop:disable Lint/UnneededCopDisableDirective
  # rubocop:disable ChefDeprecations/NodeMethodsInsteadofAttributes
  group node.root_group
  # rubocop:enable ChefDeprecations/NodeMethodsInsteadofAttributes
  # rubocop:enable Lint/UnneededCopDisableDirective
  mode '0644'
end

# Debian doesn't do the redhat make-sure-non-login-shells-get-aliases
# So this is the bashrc from debian/ubuntu with that extra bit in there
if node.debian? || node.ubuntu?
  cookbook_file '/etc/bash.bashrc' do
    owner 'root'
    group 'root'
    mode '0644'
    source 'debian.bashrc'
  end
end
