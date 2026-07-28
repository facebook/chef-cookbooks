#
# Copyright (c) 2026-present, Facebook, Inc.
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

# fb_users_group is the group counterpart to fb_users_user: an imperative
# alternative to setting node['fb_users']['groups'][<name>] directly. It writes
# that same entry at compile time (see after_created); the group itself is
# created (or removed) by the fb_users recipe at converge time. See user.rb for
# why the write happens in after_created rather than in an action.

unified_mode true

default_action :add

property :groupname, String, :name_property => true
property :members, Array

# The actual create/remove is done by fb_users::default. These actions exist
# only so `action :add` / `action :delete` read naturally in the DSL; the
# add/delete decision is recorded into the attribute in `after_created`.
action :add do
  Chef::Log.debug(
    "fb_users_group[#{new_resource.groupname}]: materialized by fb_users",
  )
end

action :delete do
  Chef::Log.debug(
    "fb_users_group[#{new_resource.groupname}]: removal handled by fb_users",
  )
end

def after_created
  data = {}
  data['members'] = members unless members.nil?
  data['action'] = Array(action).first
  node.default['fb_users']['groups'][groupname] = data
end
