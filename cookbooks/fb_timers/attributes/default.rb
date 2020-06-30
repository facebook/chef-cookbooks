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

default['fb_timers'] = {
  'jobs' => {},

  'enable_named_slices' => true,

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
  '_reload_needed' => false,
  'optional_keys' => [],
}
