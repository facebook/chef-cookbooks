#
# Cookbook Name:: fb_chef_hints
# Recipe:: common
#
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

hints_base = ::File.join(node.host_chef_base_path, FB::ChefHints::HINTS_BASE)

directory hints_base do
  owner node.root_user
  group node.root_group
  if node.windows?
    rights :read_execute, 'Everyone'
    rights :full_control, 'Administrators'
  else
    mode '0755'
  end
end
