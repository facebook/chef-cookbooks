#
# Cookbook Name:: fb_syslog
# Recipe:: enable
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

# this is almost identical to running 'systemctl enable rsyslog', except that it
# has no run-time requirements and can be run while setting up a container.

if node.systemd?
  link '/etc/systemd/system/syslog.service' do
    to '/usr/lib/systemd/system/rsyslog.service'
    owner 'root'
    group 'root'
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
  end
end
