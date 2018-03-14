# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

default['fb_ipset'] = {
  'manage_packages' => true,
  'enable' => false,
  'auto_cleanup' => true,
  'sets' => {},
  'state_file' => if node.centos6?
                    '/etc/sysconfig/ipset'
                  else
                    '/etc/ipset/ipset'
                  end,
}
