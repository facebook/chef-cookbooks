#
# Cookbook Name:: fb_jq
# Recipe:: packages
#
# Copyright 2014, Facebook
#
# All rights reserved - Do Not Redistribute
#
unless node.centos?
  fail 'fb_jq only supports CentOS'
end

package 'jq' do
  action :upgrade
end
