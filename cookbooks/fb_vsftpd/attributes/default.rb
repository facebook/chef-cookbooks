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
