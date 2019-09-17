#
# Cookbook Name:: fb_cron
# Recipe:: packages
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

case node['platform_family']
when 'rhel', 'fedora', 'suse'
  package_name = 'vixie-cron'
  if node['platform'] == 'amazon' || node['platform_version'].to_i >= 6
    package_name = 'cronie'
  end
when 'debian'
  package_name = 'cron'
end

if package_name # ~FC023
  package package_name do
    action :upgrade
  end
end
