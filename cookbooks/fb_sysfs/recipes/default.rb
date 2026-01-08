# Copyright (c) Meta Platforms, Inc. and affiliates.
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

template '/etc/sysfs_files_on_boot' do
  source 'sysfs_on_boot.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  variables(:resource_hash=> lazy { node['fb_sysfs']['_set_on_boot'] })
  delayed_action :create
  action :nothing
end

template '/usr/local/bin/set_sysfs_on_boot.py' do
  source 'set_sysfs_on_boot.py.erb'
  owner node.root_user
  group node.root_group
  mode '0755'
  action :create
end

systemd_unit 'set_sysfs_on_boot.service' do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=Run populating sysfs at boot
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/set_sysfs_on_boot.py
  TimeoutStartSec=1m
  TimeoutStopSec=2m

  [Install]
  WantedBy=default.target
  EOU
  action [:create, :enable]

end
