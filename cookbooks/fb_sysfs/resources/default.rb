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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :set

property :path, String, :name_property => true
property :value, [String, Integer, :EINVAL], :required => true
property :type, Symbol, :required => true
property :ignore_einval, [true, false], :default => false
# allows clients to pass in a callback to be used instead of a direct read
property :read_method, Method, :required => false
property :set_on_boot, [true, false], :default => false

action_class do
  include FB::Sysfs::Provider
end

load_current_value do |new_resource|
  # read normally when no custom read_method is present and path exists
  if !new_resource.read_method && ::File.exist?(path)
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
  if new_resource.read_method
    update_needed = new_resource.read_method.call(node, new_resource.path,
                                                  new_resource.value)
    unless [TrueClass, FalseClass].include?(update_needed.class)
      fail 'fb_sysfs: read_method must return a boolean, got ' +
        "#{update_needed.class}!"
    end

    if update_needed
      Chef::Log.debug(
        "fb_sysfs #{new_resource.path}: custom read method indicates update " +
        'is needed',
      )

      converge_by("writing #{new_resource.value} to #{new_resource.path}") do
        ::File.write(new_resource.path, new_resource.value.to_s)

        Chef::Log.debug("fb_sysfs #{new_resource.path}: value written " +
                        new_resource.value.to_s)

      end
    else
      Chef::Log.debug(
        "fb_sysfs #{new_resource.path}: custom read indicates no update is " +
        'needed',
      )
    end
  elsif current_resource.value == :EINVAL
    if new_resource.ignore_einval
      Chef::Log.warn("fb_sysfs: ignoring EINVAL on #{new_resource.path} as " +
                     'requested, resource will be left unmanaged!  This resource will
                     not be set_on_boot')

      if new_resource.set_on_boot
        fail 'fb_sysfs set_on_boot has been set with ignore EINVAL.  This will not set sysfs files on boot.'
      end
    else
      fail "fb_sysfs: got EINVAL on #{new_resource.path} and ignore_einval " +
           'is false, aborting!'
    end
  elsif check(current_resource.value, new_resource.value, new_resource.type)
    if new_resource.set_on_boot
      create_set_on_boot_hash(node, new_resource.type, new_resource.path, new_resource.value)
      Chef::Log.debug("fb_sysfs #{new_resource.path}: value #{new_resource.value} will be set on boot.")
    end
    Chef::Log.debug(
      "fb_sysfs #{new_resource.path}: Value set correctly, nothing to do. " +
      "Current value: #{current_resource.value.inspect}",
    )
  else
    if new_resource.set_on_boot
      create_set_on_boot_hash(node, new_resource.type, new_resource.path, new_resource.value)
      Chef::Log.debug("fb_sysfs #{new_resource.path}: value #{new_resource.value} will be set on reboot.")
    end
    # We are using file to write content, not to manage the file itself,
    # so we exempt the internal foodcritic rule that requires owner/group/mode.
    file new_resource.path do # rubocop:disable Chef/Meta/RequireOwnerGroupMode
      if new_resource.type == :list
        # Some :list sysfs require a newline at the end of the value to take
        # effect. For others, the newline is ignored, so always write one (and
        # only one) out regardless.
        content "#{new_resource.value.to_s.chomp}\n"
      else
        content new_resource.value.to_s
      end
    end
  end
end
