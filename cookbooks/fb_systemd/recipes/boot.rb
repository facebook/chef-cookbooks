#
# Cookbook Name:: fb_systemd
# Recipe:: boot
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
