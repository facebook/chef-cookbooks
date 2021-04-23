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

package 'tcpdump' do
  action :upgrade
end
