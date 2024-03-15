#
# Cookbook Name:: fb_gpsd_clients
# Recipe:: packages
#
# Copyright 2014, Facebook
#
# All rights reserved - Do Not Redistribute
#
unless node.centos?
  fail 'fb_gpsd_clients only supports CentOS'
end

package 'gpsd-clients' do
  action :remove
end

package 'gpsd-minimal-clients' do
  action :upgrade
end
