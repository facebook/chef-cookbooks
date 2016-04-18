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

include FB::FstabProvider

def whyrun_supported?
  true
end

action :doeverything do
  # Unmount filesystems we don't want
  check_unwanted_filesystems
  # Mount or update filesystems we want
  check_wanted_filesystems
end
