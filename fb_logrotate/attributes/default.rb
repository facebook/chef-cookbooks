# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant 
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_logrotate'] = {
  'globals' => {
    'rotate' => '14',
    'maxage' => '14',
    'compresscmd' => '/usr/bin/pigz',
  },
  'configs' => {},
  'add_locking_to_logrotate' => false,
}
