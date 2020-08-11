# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2020-present, Facebook, Inc.
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

property :path, String, :name_property => true
property :object, Object, :required => true
property :filter, [Array, String]
property :owner, String
property :group, String
property :mode, String
property :rights, String

default_action :create

action :create do
  Chef::Log.debug(
    "fb_helpers: dumping #{new_resource.object.class} to #{new_resource.path}",
  )

  if new_resource.filter
    unless new_resource.object.is_a?(Hash)
      fail 'fb_helpers: filtering is only supported for Hash objects ' +
        "(actual: #{new_resource.object.class})"
    end
    data = FB::Helpers.filter_hash(new_resource.object, new_resource.filter)
  else
    data = new_resource.object
  end

  file new_resource.path do
    content JSON.pretty_generate(data)
    if new_resource.owner
      owner new_resource.owner
    end
    if new_resource.group
      group new_resource.group
    end
    if new_resource.rights
      rights new_resource.rights
    end
    if new_resource.mode
      mode new_resource.mode
    end
  end
end
