# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
