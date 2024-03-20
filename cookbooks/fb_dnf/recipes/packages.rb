#
# Cookbook Name:: fb_dnf
# Recipe:: packages
#
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

dnf_packages = %w{
  dnf
  dnf-data
  dnf-plugins-core
  dnf-utils
  libcomps
  libdnf
  libsolv
  python3-dnf
  python3-dnf-plugins-core
  python3-libcomps
}

package dnf_packages do
  only_if { node['fb_dnf']['manage_packages'] }
  action :install
end
