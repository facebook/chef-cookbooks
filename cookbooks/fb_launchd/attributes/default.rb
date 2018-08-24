# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_launchd'] = {
  # Prefix all launchd agents/daemons will be created under.
  'prefix' => 'com.facebook.managed',

  # Any user-specified jobs to manage. Attributes are those used by the launchd
  # resource. See README.md for more details.
  'jobs' => {},
}
