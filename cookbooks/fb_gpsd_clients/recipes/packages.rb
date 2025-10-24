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

if node.centos10?
  package 'gpsd-clients' do
    action :upgrade
  end
else
  package 'gpsd-minimal-clients' do
    action :upgrade
  end
end
