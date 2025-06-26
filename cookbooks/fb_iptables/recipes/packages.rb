# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_iptables
# Recipe:: packages
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

# In modern Fedora and C9 and above, iptables-nft contains everything
# that iptables-legacy does, they overlap (with iptables-legacy being
# a strict subset), and both packages 'providing' `iptables`
#
# In EL10/C10 and above, it's the same but iptables-nft
# obsoletes iptables-services, so they cannot both be installed.
if node.el_min_version?(9) || node.fedora?
  packages = ['iptables-nft']
else
  packages = ['iptables']
end

if node.debian_family?
  packages << 'iptables-persistent'
elsif node.el_min_version?(9)
  # In EL9/C9 and above, iptables-nft-services contains everything
  # that iptables-services does, they overlap.
  #
  # In EL10/C10 and above, it's the same but iptables-nft-services
  # obsoletes iptables-services
  #
  # In Fedora there is only 'iptables-services', and it's the
  # superset package (like iptables-nft-services in EL)
  packages << 'iptables-nft-services'
else
  packages << 'iptables-services'
end

package packages do
  only_if { node['fb_iptables']['manage_packages'] }
  action :upgrade
  notifies :run, 'execute[reload iptables]'
  notifies :run, 'execute[reload ip6tables]'
end

execute 'reload iptables' do
  only_if { node['fb_iptables']['enable'] }
  command '/usr/bin/fb_iptables_reload 4 reload'
  action :nothing
end

## ip6tables ##
execute 'reload ip6tables' do
  only_if { node['fb_iptables']['enable'] }
  command '/usr/bin/fb_iptables_reload 6 reload'
  action :nothing
end
