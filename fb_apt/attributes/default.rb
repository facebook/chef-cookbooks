# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

if node.debian?
  mirror = 'http://http.debian.net/debian'
elsif node.ubuntu?
  mirror = 'http://archive.ubuntu.com/ubuntu'
end

default['fb_apt'] = {
  'config' => {},
  'repos' => [],
  'keys' => {},
  'keyring' => '/etc/apt/trusted.gpg',
  'keyserver' => 'keys.gnupg.net',
  'mirror' => mirror,
  'preferences' => {},
  'preserve_sources_list_d' => false,
  'update_delay' => 86400,
  'want_backports' => false,
  'want_non_free' => false,
  'want_source' => false,
}
