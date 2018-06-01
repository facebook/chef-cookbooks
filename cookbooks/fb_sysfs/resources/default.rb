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

default_action :set

property :path, :name_property => true
property :value, :is => [String, Integer], :required => true
property :type, :is => Symbol, :required => true, :default => :string

def whyrun_supported?
  true
end

action_class do
  include FB::Sysfs
end

load_current_value do
  if ::File.exist?(path)
    value ::File.read(path)
  end
end

action :set do
  if check(current_resource.value, new_resource.value, new_resource.type)
    Chef::Log.debug(
      "fb_sysfs #{new_resource.path}: Value set correctly, nothing to do. " +
      "Current value: #{current_resource.value.inspect}",
    )
  else
    converge_by("set #{new_resource.path} to #{new_resource.value.inspect} " +
                "(was #{current_resource.value.inspect})") do
      IO.write(new_resource.path, new_resource.value)
    end
  end
end
