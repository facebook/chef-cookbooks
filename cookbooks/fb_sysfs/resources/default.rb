#
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

default_action :set

property :path, :name_property => true
property :value, :is => [String, Integer, :EINVAL], :required => true
property :type, :is => Symbol, :required => true, :default => :string
property :ignore_einval, :is => [TrueClass, FalseClass], :required => true,
                         :default => false

def whyrun_supported?
  true
end

action_class do
  include FB::Sysfs::Provider
end

load_current_value do
  if ::File.exist?(path)
    begin
      value ::File.read(path)
    rescue SystemCallError => e
      if e.errno == Errno::EINVAL::Errno
        Chef::Log.debug("fb_sysfs: got EINVAL trying to read #{path}")
        value :EINVAL
      else
        raise e
      end
    end
  end
end

action :set do
  if current_resource.value == :EINVAL
    if new_resource.ignore_einval
      Chef::Log.warn("fb_sysfs: ignoring EINVAL on #{new_resource.path} as " +
                     'requested, resource will be left unmanaged!')
      return
    else
      fail "fb_sysfs: got EINVAL on #{new_resource.path} and ignore_einval " +
           'is false, aborting!'
    end
  end

  if check(current_resource.value, new_resource.value, new_resource.type)
    Chef::Log.debug(
      "fb_sysfs #{new_resource.path}: Value set correctly, nothing to do. " +
      "Current value: #{current_resource.value.inspect}",
    )
  else
    # We are using file to write content, not to manage the file itself,
    # so we exempt the internal foodcritic rule that requires owner/group/mode.
    file new_resource.path do # ~FB023
      content new_resource.value.to_s
    end
  end
end
