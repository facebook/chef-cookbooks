#
# Cookbook Name:: fb_tcpdump
# Recipe:: packages
#
# Copyright 2014, Facebook
#
# All rights reserved - Do Not Redistribute
#
unless node.centos?
  fail 'fb_tcpdump only supports CentOS'
end

include_recipe_at_converge_time 'fb_tcpdump::packages_upgrade' do
  only_if { node['fb_tcpdump']['manage_packages'] }
end
