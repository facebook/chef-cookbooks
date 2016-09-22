# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

bad_users = %w{
  root
  daemon
  bin
  sys
  sync
  games
  man
  lp
  mail
  news
  uucp
  nobody
}

if node.centos?
  bad_users += %w{
    adm
    operator
    shutdown
    halt
  }
end

default['fb_vsftpd'] = {
  'enable' => true,
  'config' => {
    'listen' => true,
    'anonymous_enable' => true,
    'dirmessage_enable' => true,
    'use_localtime' => true,
    'xferlog_enable' => true,
    'connect_from_port_20' => true,
    'secure_chroot_dir' => '/var/run/vsftpd/empty',
    'pam_service_name' => 'vsftpd',
    'userlist_enable' => true,
  },
  'ftpusers' => bad_users,
  'user_list' => bad_users,
}
