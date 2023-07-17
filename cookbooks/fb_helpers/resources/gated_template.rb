# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

# This resource will change the template only when network changes
# are allowed.  If it is not allowed, it will request permission to make
# network changes.
property :allow_changes, :kind_of => [TrueClass, FalseClass], :required => true
property :path, [String, nil], :required => false
property :source, String, :required => true
property :variables, [Hash, nil], :required => false, :default => nil
property :owner, String, :required => true
property :group, String, :required => true
property :mode, String, :required => true
property :gated_action, Symbol, :required => false, :default => :create

default_action :manage

action_class do
  # Copied from lib/chef/runner.rb
  def forced_why_run
    saved = Chef::Config[:why_run]
    Chef::Config[:why_run] = true
    yield
  ensure
    Chef::Config[:why_run] = saved
  end
end

action :manage do
  t = build_resource(:template, new_resource.name) do
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    path new_resource.path if new_resource.path
    source new_resource.source
    variables new_resource.variables if new_resource.variables
    action :nothing
  end
  forced_why_run do
    t.run_action(new_resource.gated_action)
  end
  if t.updated_by_last_action?
    if new_resource.allow_changes
      Chef::Log.info('fb_helpers: changes are allowed - updating ' +
                     new_resource.name.to_s)
      template new_resource.name do
        owner new_resource.owner
        group new_resource.group
        mode new_resource.mode
        path new_resource.path if new_resource.path
        source new_resource.source
        variables new_resource.variables if new_resource.variables
        action new_resource.gated_action
      end
    else
      Chef::Log.info('fb_helpers: not allowed to change configs for ' +
                     new_resource.name.to_s)
      Chef::Log.info('fb_helpers: requesting nw change permission')
      FB::Helpers._request_nw_changes_permission(run_context, new_resource)
    end
  end
end
