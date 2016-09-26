# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_apt_cacher'] = {
  'config' => {
    'CacheDir' => '/var/cache/apt-cacher-ng',
    'LogDir' => '/var/log/apt-cacher-ng',
    'SupportDir' => '/usr/lib/apt-cacher-ng',
    'Port' => 3142,
    'Remap-debrep' => 'file:deb_mirror*.gz /debian ; file:backends_debian',
    'Remap-uburep' => 'file:ubuntu_mirrors /ubuntu ; file:backends_ubuntu',
    'Remap-debvol' =>
      'file:debvol_mirror*.gz /debian-volatile ; file:backends_debvol',
    'Remap-cygwin' => 'file:cygwin_mirrors /cygwin',
    'Remap-sfnet' => 'file:sfnet_mirrors',
    'Remap-alxrep' => 'file:archlx_mirrors /archlinux',
    'Remap-fedora' => 'file:fedora_mirrors',
    'Remap-epel' => 'file:epel_mirrors',
    'Remap-slrep' => 'file:sl_mirrors',
    'Remap-gentoo' => 'file:gentoo_mirrors.gz /gentoo ; file:backends_gentoo',
    'ReportPage' => 'acng-report.html',
    'ExThreshold' => 4,
    'ConnectProto' => 'v4 v6',
    'LocalDirs' => 'acng-doc /usr/share/doc/apt-cacher-ng',
  },
  'security' => {},
  'sysconfig' => {
    'daemon_opts' => '-c /etc/apt-cacher-ng',
  },
}
