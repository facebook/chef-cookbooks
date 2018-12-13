# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['fb_timers'] = {
  'jobs' => {},

  # Path to use for timer-related unit files.
  # We keep them in a directory separate from normal unit files so we can
  # delete them when they are removed from fb_timers attributes. If they
  # were mixed into the normal system unit files, we wouldn't be able to
  # tell which were owned by fb_timers when they are deleted, leaving stale
  # services/timers around.
  # This is a node attribute so that it can be modified during a chef run,
  # but it's hidden because nobody should do this unless they know what
  # they're doing.
  '_timer_path' => '/etc/systemd/timers'.freeze,
}
