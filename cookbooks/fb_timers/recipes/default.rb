# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook Name:: fb_timers
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.systemd?
  fail 'fb_timers is only available for use on systemd-managed machines.'
end

whyrun_safe_ruby_block 'chef systemd version' do
  action :run
  block do
    # We want to ensure this
    # https://github.com/systemd/systemd/commit/f777b4345e8c57e739bda746f78757d0fb136ac7
    # behavior changed in systemd we using with fb_timers cookbook.
    min_version = '231'
    if node.centos? && !node.centos7?
      helper = Chef::Provider::Package::Dnf::PythonHelper.instance
      # this casting to string isn't beautifull, but
      # for some reasons epoch breaks comparsion later
      installed_version = helper.query(:whatinstalled, 'systemd').version.
                          to_s.gsub(/^[0-9]+:/, '')
    elsif node.centos? && node.centos7?
      yc = Chef::Provider::Package::Yum::YumCache.instance
      installed_version = yc.installed_version('systemd')
    else
      Chef::Log.debug('Using ohai attribute to determine systemd version')
      installed_version = node['packages']['systemd']['version']
    end
    min_version = FB::Version.new(min_version)
    major_version = FB::Version.new(installed_version)
    Chef::Log.debug("Comparing version #{major_version} against #{min_version}")
    if major_version < min_version
      fail "systemd version must be at least #{min_version}." +
        "Found #{major_version}"
    end
  end
end

# This is not necessary for prod chef, but is necessary for the unit tests
# of this cookbook, since they don't run fb_systemd in any other way.
include_recipe 'fb_systemd::default'

# The default timer location
directory '/etc/systemd/timers' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# The custom timer location (if different from the default)
# We create the default in addition to the custom path so the custom path
# can be inside the default path (e.g. /etc/systemd/timers/foo_bar)
directory 'timer path' do
  path lazy {
    node['fb_timers']['_timer_path']
  }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if do
    node['fb_timers']['_timer_path'] != '/etc/systemd/timers'
  end
end

file 'fb_timers readme' do
  path lazy {
    "#{node['fb_timers']['_timer_path']}/README"
  }
  content "This directory is managed by the chef cookbook fb_timers.\n" +
          'DO NOT put unit files here; they will be deleted.'
  mode '0644'
  owner 'root'
  group 'root'
end

fb_timers_setup 'fb_timers system setup'
