#
# Cookbook Name:: fb_systemd
# Recipe:: resolved
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

template '/etc/systemd/resolved.conf' do
  source 'systemd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :config => 'resolved',
    :section => 'Resolve',
  )
  notifies :restart, 'service[systemd-resolved]'
end

# nss-resolve enables DNS resolution via the systemd-resolved DNS/LLMNR caching
# stub resolver. According to upstream this should replace the glibc "dns"
# resolver and is required for systemd-resolved to work. This block attempts
# to place the resolver between mymachines and myhostname as recommended by
# upstream.
ruby_block 'enable nss-resolve' do
  only_if { node['fb_systemd']['resolved']['enable'] }
  block do
    node.default['fb_nsswitch']['databases']['hosts'].delete('dns')
    idx = node['fb_nsswitch']['databases']['hosts'].index('mymachines')
    if idx
      node.default['fb_nsswitch']['databases']['hosts'].insert(idx + 1,
                                                               'resolve')
    else
      idx = node['fb_nsswitch']['databases']['hosts'].index('myhostname')
      if idx
        node.default['fb_nsswitch']['databases']['hosts'].insert(idx - 1,
                                                                 'resolve')
      else
        node.default['fb_nsswitch']['databases']['hosts'] << 'resolve'
      end
    end
  end
end

service 'systemd-resolved' do
  only_if { node['fb_systemd']['resolved']['enable'] }
  action [:enable, :start]
end

service 'disable systemd-resolved' do
  not_if { node['fb_systemd']['resolved']['enable'] }
  service_name 'systemd-resolved'
  action [:stop, :disable]
end
