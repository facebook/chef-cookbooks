# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_hosts'] = {
  'host_aliases' => [],
  'primary_ipaddress' => nil,
  'primary_ip6address' => nil,
  'extra_entries' => {},
  'enable_hostname_entries' => true,
}
