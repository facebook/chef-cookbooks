#
# Cookbook Name:: fb_grub
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

# Keep this in sync with the platform list in attributes
unless %{centos debian fedora redhat ubuntu}.include?(node['platform'])
  fail "fb_grub: this platform is not supported: #{node['platform']}"
end

include_recipe 'fb_grub::packages'
include_recipe 'fb_grub::validate'
include_recipe 'fb_grub::config'
