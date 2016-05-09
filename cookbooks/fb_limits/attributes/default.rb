# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_limits']['root'] = {
  'nofile' => {
    'hard' => '65535',
    'soft' => '65535',
  },
}

# Only set limit on centos6 as centos5 has a very high default limit already.
# CentOS 6 defaults to 1024
if node.centos6?
  default['fb_limits']['*'] = {
    'nproc' => {
      'hard' => '61278',
      'soft' => '61278',
    },
  }
end
