#
# Cookbook Name:: fb_dbus
# Recipe:: packages
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2011-present, Facebook
#
# All rights reserved - Do Not Redistribute
#

# dbus-broker relies on the dbus packages, so we install those unconditionally
package %w{dbus dbus-libs} do
  only_if { node['fb_dbus']['manage_packages'] }
  action :upgrade
end

package 'dbus-broker' do
  only_if do
    node['fb_dbus']['manage_packages'] &&
      (node['fb_dbus']['implementation'] == 'dbus-broker')
  end
  action :upgrade
end
