# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

ttys = [
  'console',
  'tty1',
  'tty2',
  'tty3',
  'tty4',
  'tty5',
  'tty6',
  'tty7',
  'tty8',
  'tty9',
  'tty10',
  'tty11',
]

if node.centos?
  ttys += [
    'vc/1',
    'vc/2',
    'vc/3',
    'vc/4',
    'vc/5',
    'vc/6',
    'vc/7',
    'vc/8',
    'vc/9',
    'vc/10',
    'vc/11',
  ]
end

default['fb_securetty'] = {
  'ttys' => ttys,
}
