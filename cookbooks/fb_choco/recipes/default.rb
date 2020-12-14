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
# Cookbook Name:: fb_choco
# Recipe:: default

unless node.windows?
  fail 'fb_choco is only supported on Windows.'
end

fb_choco_bootstrap 'Install Chocolatey if needed' do
  only_if { node['fb_choco']['enabled']['bootstrap'] }
end

fb_choco_configure 'configuring chocolatey client' do
  sources lazy { node['fb_choco']['sources'] }
  config  lazy { node['fb_choco']['config'] }
  features lazy { node['fb_choco']['features'] }
  only_if { node['fb_choco']['enabled']['manage'] }
  action :change
end
