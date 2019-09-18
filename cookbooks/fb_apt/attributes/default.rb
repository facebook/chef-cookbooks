# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node.debian?
  mirror = 'http://httpredir.debian.org/debian'
  security_mirror = 'http://security.debian.org/'
  # on Debian the base keys are provided by the debian-archive-keyring package
  # and stored in a separate keyring, so there's no need to manage them here
  keys = {}
elsif node.ubuntu?
  mirror = 'http://archive.ubuntu.com/ubuntu'
  security_mirror = 'http://security.ubuntu.org/ubuntu'
  # Ubuntu Archive signing keys -- these are provided by the ubuntu-keyring
  # package and merged into the main keyring, we list them here so they don't
  # get clobbered
  keys = {
    '40976EAF437D05B5' => nil,
    '46181433FBB75451' => nil,
    '3B4FE6ACC0B21F32' => nil,
    'D94AA3F0EFE21092' => nil,
    '0BFB847F3F272F5B' => nil,
  }
end

default['fb_apt'] = {
  'config' => {},
  'repos' => [],
  'keys' => keys,
  'keyring' => '/etc/apt/trusted.gpg',
  'keyserver' => 'keys.gnupg.net',
  'mirror' => mirror,
  'security_mirror' => security_mirror,
  'preferences' => {},
  'preserve_sources_list_d' => false,
  'update_delay' => 86400,
  'want_backports' => false,
  'want_non_free' => false,
  'want_source' => false,
}
