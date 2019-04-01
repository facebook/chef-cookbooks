#
# Cookbook Name:: fb_systemd
# Recipe:: boot
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

directory 'loader path' do
  only_if do
    node['fb_systemd']['boot']['enable'] && node['fb_systemd']['boot']['path']
  end
  path lazy { "#{node['fb_systemd']['boot']['path']}/loader" }
  owner 'root'
  group 'root'
  mode '0755'
end

template 'loader.conf' do
  only_if do
    node['fb_systemd']['boot']['enable'] && node['fb_systemd']['boot']['path']
  end
  path lazy { "#{node['fb_systemd']['boot']['path']}/loader/loader.conf" }
  source 'loader.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory 'loader entries path' do
  only_if do
    node['fb_systemd']['boot']['enable'] && node['fb_systemd']['boot']['path']
  end
  path lazy { "#{node['fb_systemd']['boot']['path']}/loader/entries" }
  owner 'root'
  group 'root'
  mode '0755'
end

fb_systemd_loader_entries 'process loader entries'

execute 'install systemd-boot' do
  only_if do
    node['fb_systemd']['boot']['enable'] &&
    node['fb_systemd']['boot']['path'] &&
    !File.exist?(
      "#{node['fb_systemd']['boot']['path']}/EFI/systemd/systemd-bootx64.efi",
    ) && !File.exist?(
      "#{node['fb_systemd']['boot']['path']}/efi/systemd/systemd-bootx64.efi",
    )
  end
  command lazy {
    "bootctl --path=#{node['fb_systemd']['boot']['path']} install"
  }
end

execute 'update systemd-boot' do
  only_if do
    node['fb_systemd']['boot']['enable'] &&
    node['fb_systemd']['boot']['path']
  end
  command lazy {
    "bootctl --path=#{node['fb_systemd']['boot']['path']} update"
  }
  action :nothing
  subscribes :run, 'package[systemd-packages]'
end

execute 'remove systemd-boot' do
  only_if do
    !node['fb_systemd']['boot']['enable'] &&
    node['fb_systemd']['boot']['path'] && (
    File.exist?(
      "#{node['fb_systemd']['boot']['path']}/EFI/systemd/systemd-bootx64.efi",
    ) || File.exist?(
      "#{node['fb_systemd']['boot']['path']}/efi/systemd/systemd-bootx64.efi",
    ))
  end
  command lazy {
    "bootctl --path=#{node['fb_systemd']['boot']['path']} remove"
  }
end
