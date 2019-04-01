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

require 'fileutils'

default_action :doeverything

def whyrun_supported?
  true
end

action_class do
  def reload_filesystems
    ohai 'reload filesystems for fb_fstab' do
      if node['filesystem2']
        plugin 'filesystem2'
      else
        plugin 'filesystem'
      end
      action :nothing
    end.run_action(:reload)
  end
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
