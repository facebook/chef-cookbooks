# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require 'fileutils'

def whyrun_supported?
  true
end

def reload_filesystems
  ohai 'reload filesystems for fb_fstab' do
    plugin 'filesystem2'
    action :nothing
  end.run_action(:reload)
end

action :doeverything do
  extend FB::FstabProvider

  # Unmount filesystems we don't want
  check_unwanted_filesystems
  # Reload in case something has been unmounted
  reload_filesystems
  # Mount or update filesystems we want
  check_wanted_filesystems
end
