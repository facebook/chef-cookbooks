# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

property :override_name, String, :name_property => true
property :unit_name, String, :required => true
property :content, [String, Hash], :required => false
property :source, String, :required => false
property :triggers_reload, [true, false], :default => true
property :instance, :kind_of => String, :default => 'system'

default_action :create

action_class do
  def get_override_dir
    "/etc/systemd/#{new_resource.instance}/#{new_resource.unit_name}.d"
  end

  def get_reload_resource
    if new_resource.instance == 'user'
      'fb_systemd_reload[all user instances]'
    else
      'fb_systemd_reload[system instance]'
    end
  end
end

action :create do
  if new_resource.source && new_resource.content
    fail 'fb_systemd: cannot pass both source and content at the same time ' +
         'with fb_systemd_override, you need to pick one. Aborting!'
  end
  if !new_resource.source && !new_resource.content
    fail 'fb_systemd: either source or content are required with ' +
         'fb_systemd_override but neither was passed, aborting!'
  end
  if new_resource.instance != 'system' && new_resource.instance != 'user'
    fail 'fb_systemd: instance has to be either "system" or "user" ' +
          'in fb_systemd_override. Aborting!'
  end

  override_dir = get_override_dir
  override_file = "#{FB::Systemd.sanitize(new_resource.override_name)}.conf"

  directory override_dir do
    owner 'root'
    group 'root'
    mode '0755'
  end

  template ::File.join(override_dir, override_file) do # ~FB031 ~FB032
    # If source is specified, use it, otherwise use our template...
    if new_resource.source
      source new_resource.source
    else
      cookbook 'fb_systemd'
      source 'systemd-override.conf.erb'
    end
    owner 'root'
    group 'root'
    mode '0644'
    # ... and rely on content to populate the override
    unless new_resource.source
      variables({
                  'content' => new_resource.content,
                })
    end
    if new_resource.triggers_reload
      notifies :run,
               get_reload_resource,
               :immediately
    end
  end
end

action :delete do
  override_dir = get_override_dir
  override_file = "#{FB::Systemd.sanitize(new_resource.override_name)}.conf"

  if ::Dir.exist?(override_dir)
    file ::File.join(override_dir, override_file) do
      action :delete
      if new_resource.triggers_reload
        notifies :run,
                 get_reload_resource,
                 :immediately
      end
    end

    # if the override directory is empty, there's no reason to keep it around so
    # we reap it as well; this is done here to ensure multiple overrides can be
    # defined against the same unit
    #
    # NOTE: we're not using Dir.empty? here as that was added in ruby 2.4, and
    # Chef 12 is still on 2.3
    if (::Dir.entries(override_dir) - %w{. ..}).empty?
      directory override_dir do
        action :delete
      end
    end
  end
end
