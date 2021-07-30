# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_chrony
# Recipe:: packages
#
# Copyright (c) 2019-present, Facebook, Inc.
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

if node.centos8?
  # We don't have any rolloug phases yet.
  node.default['fb_slowroll']['fb_chrony']['phases'] = []
  fb_slowroll 'chrony' do
    only_if { node['fb_chrony']['manage_packages'] }
  end
else
  package 'chrony' do
    only_if { node['fb_chrony']['manage_packages'] }
    action :upgrade
  end
end
