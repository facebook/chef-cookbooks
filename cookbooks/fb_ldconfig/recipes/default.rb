#
# Cookbook Name:: fb_ldconfig
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

unless node.centos?
  fail 'fb_ldconfig is only supported on CentOS'
end

execute 'ldconfig' do
  command '/sbin/ldconfig'
  action :nothing
end

cookbook_file '/etc/ld.so.conf' do
  source 'ld.so.conf'
  owner 'root'
  group 'root'
  mode '0644'
  # immediately because stuff in the run probably needs this
  notifies :run, 'execute[ldconfig]', :immediately
end

template '/etc/ld.so.conf.d/chef.conf' do
  source 'ld.so.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # immediately because stuff in the run probably needs this
  notifies :run, 'execute[ldconfig]', :immediately
end

files = Dir.glob('/etc/ld.so.conf.d/*').reject do |x|
  File.basename(x) == 'chef.conf'
end
unless files.empty?
  # RPM will exit with zero if all the files are owned by a package, and
  # non-zero if there are any strays.
  s = Mixlib::ShellOut.new("/bin/rpm -qf #{files.join(' ')}").run_command
  if s.exitstatus != 0
    # Parse the RPM output to find the strays and delete them
    s.stdout.split("\n").each do |line|
      m = /file (.*) is not owned by any package/.match(line.strip)
      next unless m

      file m[1] do
        action :delete
        notifies :run, 'execute[ldconfig]', :immediately
      end
    end
  end
end
