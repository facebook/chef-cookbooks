#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

if node.centos?
  excludes = [
    '.X11-unix',
    '.XIM-unix',
    '.font-unix',
    '.ICE-unix',
    '.Test-unix',
  ]
else
  excludes = [
    '.X*-{lock,unix,unix/*}',
    'ICE-{unix,unix/*}',
    '.iroha_{unix,unix/*}',
    '.ki2-{unix,unix/*}',
    'lost+found',
    'journal.dat',
    'quota.{user,group}',
  ]
end

default['fb_tmpclean'] = {
  'default_files' => 240,
  'directories' => {},
  'timestamptype' => 'mtime',
  'extra_lines' => [],
  'excludes' => excludes,
  'remove_special_files' => false,
}
