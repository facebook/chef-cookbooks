#
# Cookbook Name:: fb_systemd
# Recipe:: journal-gatewayd
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

service 'systemd-journal-gatewayd' do
  only_if { node['fb_systemd']['journal-gatewayd']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-journal-gatewayd' do
  not_if { node['fb_systemd']['journal-gatewayd']['enable'] }
  service_name 'systemd-journal-gatewayd'
  action [:stop, :disable]
end
