#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

action :install do
  pkg_url = FB::Openport.download_url(node)
  pkg_filename = ::File.basename(pkg_url)
  pkg_path = ::File.join(Chef::Config[:file_cache_path], pkg_filename)

  remote_file 'openport package' do
    path pkg_path
    source pkg_url
  end

  if ChefUtils.debian?
    # Oddly the apt provider can't handle source, only dpkg can
    dpkg_package 'openport' do
      version node['fb_openport']['version']
      source pkg_path
      action :install
    end
  elsif ChefUtils.fedora_derived?
    dnf_package 'openport' do
      version node['fb_openport']['version']
      source pkg_path
      action :install
    end
  else
    fail 'fb_openport: Do not know how to install a package from source on' +
      " this platform (#{node['platform']}). Please set `manage_packages` to" +
      ' false.'
  end
end
