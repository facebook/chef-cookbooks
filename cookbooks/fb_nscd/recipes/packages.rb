#
# Cookbook Name:: fb_nscd
# Recipe:: packages
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012, Facebook
#
# All rights reserved - Do Not Redistribute
#

package 'nscd' do
  only_if { FB::Nscd.nscd_enabled?(node) }
  action :upgrade
end
