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
  mirror = 'http://httpredir.debian.org/debian'
  # on Debian the base keys are provided by the debian-archive-keyring package
  # and stored in a separate keyring, so there's no need to manage them here
  keys = {}
elsif node.ubuntu?
  mirror = 'http://archive.ubuntu.com/ubuntu'
  # Ubuntu Archive signing keys -- these are provided by the ubuntu-keyring
  # package and merged into the main keyring, we list them here so they don't
  # get clobbered
  keys = {
    '437D05B5' => nil,
    'FBB75451' => nil,
    'C0B21F32' => nil,
    'EFE21092' => nil,
  }
end

default['fb_apt'] = {
  'config' => {},
  'repos' => [],
  'keys' => keys,
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
