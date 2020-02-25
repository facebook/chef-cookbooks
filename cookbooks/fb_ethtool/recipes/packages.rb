#
# Cookbook Name:: fb_ethtool
# Recipe:: packages
#
# Copyright 2014, Facebook
#
# All rights reserved - Do Not Redistribute
#

package 'ethtool' do
  action :upgrade
end
