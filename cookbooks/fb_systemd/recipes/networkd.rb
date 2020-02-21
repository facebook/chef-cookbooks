#
# Cookbook Name:: fb_systemd
# Recipe:: networkd
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
%w{
  systemd-networkd.socket
  systemd-networkd.service
}.each do |svc|
  service svc do
    only_if { node['fb_systemd']['networkd']['enable'] }
    subscribes :restart, 'package[systemd packages]', :immediately
    if svc == 'systemd-networkd.socket'
      notifies :stop, 'service[systemd-networkd.service]', :before
      notifies :start, 'service[systemd-networkd.service]', :immediately
    end
    action [:enable, :start]
  end

  service "disable #{svc}" do
    not_if { node['fb_systemd']['networkd']['enable'] }
    service_name svc
    action [:stop, :disable]
  end
end
