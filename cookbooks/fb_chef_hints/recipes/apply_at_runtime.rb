#
# Cookbook Name:: fb_chef_hints
# Recipe:: default
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

include_recipe 'fb_chef_hints::common'

hints_base = ::File.join(node.host_chef_base_path, FB::ChefHints::HINTS_BASE)
hints_glob = ::File.join(hints_base, '*.json')
hints_files = Dir.glob(hints_glob).sort
if hints_files.empty?
  Chef::Log.debug(
    "fb_chef_hints: no hints files found at #{hints_base}",
  )
else
  Chef::Log.debug(
    "fb_chef_hints: found hints files: #{hints_files.join(' ')}",
  )

  hints_files.each do |f|
    whyrun_safe_ruby_block "apply hint #{f}" do
      block do
        FB::ChefHints.apply_hint(node, f)
      end
    end
  end
end
