#
# Cookbook Name:: fb_systemd
# Recipe:: default_packages
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

systemd_packages = ['systemd']

case node['platform_family']
when 'rhel', 'fedora'
  systemd_packages << 'systemd-libs'
when 'debian'
  systemd_packages += %w{
    libpam-systemd
    libsystemd0
    libudev1
  }

  unless node.container?
    systemd_packages << 'udev'
  end

  # older versions of Debian and Ubuntu are missing some extra packages
  unless ['trusty', 'jessie'].include?(node['lsb']['codename'])
    systemd_packages += %w{
      libnss-myhostname
      libnss-mymachines
      libnss-resolve
      systemd-container
      systemd-coredump
      systemd-journal-remote
    }
  end
else
  fail 'fb_systemd is not supported on this platform.'
end

package 'systemd packages' do
  package_name systemd_packages
  only_if { node['fb_systemd']['manage_systemd_packages'] }
  action :upgrade
end
