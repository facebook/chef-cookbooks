# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_ebtables'] = {
  'enable' => false,
  'manage_packages' => true,
  'sysconfig' => {
    'binary_format' => 'yes',
    'modules_unload' => 'yes',
    'save_on_stop' => 'no',
    'save_on_restart' => 'no',
    'save_counter' => 'no',
    'text_format' => 'yes',
  },
}
