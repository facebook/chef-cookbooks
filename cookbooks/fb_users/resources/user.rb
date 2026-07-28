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

# fb_users_user is a thin, imperative alternative to setting
# `node['fb_users']['users'][<username>]` directly. It writes that same entry
# at *compile time* (see `after_created`); the user itself is still materialized
# by the `fb_users` recipe at converge time, exactly as it is for the attribute
# API. Writing the attribute at compile time (rather than in an action, which
# runs at converge) is what makes this safe to use anywhere in the run list:
# the write always lands before `fb_users` reads the attribute during converge.

unified_mode true

default_action :add

property :username, String, :name_property => true
property :gid, String
property :home, String
property :homedir_group, String
property :homedir_mode, String
property :manage_home, [TrueClass, FalseClass]
property :password, String
property :shell, String
property :secure_token, [TrueClass, FalseClass]

# The actual create/remove is done by fb_users::default. These actions exist
# only so `action :add` / `action :delete` read naturally in the DSL; the
# add/delete decision is recorded into the attribute in `after_created`.
action :add do
  Chef::Log.debug(
    "fb_users_user[#{new_resource.username}]: materialized by fb_users",
  )
end

action :delete do
  Chef::Log.debug(
    "fb_users_user[#{new_resource.username}]: removal handled by fb_users",
  )
end

def after_created
  data = {}
  data['gid'] = gid unless gid.nil?
  data['home'] = home unless home.nil?
  data['homedir_group'] = homedir_group unless homedir_group.nil?
  data['homedir_mode'] = homedir_mode unless homedir_mode.nil?
  data['manage_home'] = manage_home unless manage_home.nil?
  data['password'] = password unless password.nil?
  data['shell'] = shell unless shell.nil?
  data['secure_token'] = secure_token unless secure_token.nil?
  data['action'] = Array(action).first
  node.default['fb_users']['users'][username] = data
end
