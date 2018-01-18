#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

use_inline_resources

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::FbSysfs.new(@new_resource.path)
  @current_resource.value = ::File.read(@new_resource.path)
  Chef::Log.debug(
    "#{new_resource.value}: Current value: #{@current_resource.value}",
  )
end

action :set do
  if FB::Sysfs.check(
    current_resource.value,
    new_resource.value,
    new_resource.type,
  )
    Chef::Log.debug(
      "#{new_resource.value}: Value set correctly, nothing to do",
    )
  else
    converge_by("Setting #{new_resource.path}") do
      # We are using file to write content, not to manage the file itself,
      # so we exempt the internal foodcritic rule that requires
      # owner/group/mode.
      file new_resource.path do # ~FB023
        content new_resource.value.to_s
      end
    end
  end
end
