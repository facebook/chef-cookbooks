#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

globals = {
  'rotate' => '14',
  'maxage' => '14',
}

unless node.centos6?
  globals['compresscmd'] = '/usr/bin/pigz'
end

default['fb_logrotate'] = {
  'globals' => globals,
  'configs' => {},
  'add_locking_to_logrotate' => false,
  'debug_log' => false,
}
