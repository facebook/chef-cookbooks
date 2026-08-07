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

# The dnf package stack is expressed as JSON recipes (packages_dnf_install /
# packages_dnf5_install) so that Antlir image builds can pre-bake these RPMs
# into the image instead of installing them on every run. The platform fork
# stays here as compile-time Ruby (it depends only on stable node facts); the
# manage_packages guard moves onto include_recipe_at_converge_time because JSON
# recipes cannot carry only_if guards.
if node.fedora_min_version?(41) || node.el_min_version?(11) || node.eln?
  include_recipe_at_converge_time 'fb_dnf::packages_dnf5_install' do
    only_if { node['fb_dnf']['manage_packages'] }
  end
else
  include_recipe_at_converge_time 'fb_dnf::packages_dnf_install' do
    only_if { node['fb_dnf']['manage_packages'] }
  end
end
