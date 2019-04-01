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
property :content, [String, Hash], :required => true
property :triggers_reload, [TrueClass, FalseClass], :default => true

default_action :create

action :create do
  override_dir = "/etc/systemd/system/#{new_resource.unit_name}.d"
  override_file = "#{FB::Systemd.sanitize(new_resource.override_name)}.conf"

  directory override_dir do
    owner 'root'
    group 'root'
    mode '0755'
  end

  template ::File.join(override_dir, override_file) do # ~FB032
    cookbook 'fb_systemd'
    source 'systemd-override.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables({
                'content' => new_resource.content,
              })
    if new_resource.triggers_reload
      notifies :run, 'fb_systemd_reload[system instance]', :immediately
    end
  end
end

action :delete do
  override_dir = "/etc/systemd/system/#{new_resource.unit_name}.d"
  override_file = "#{FB::Systemd.sanitize(new_resource.override_name)}.conf"

  if ::Dir.exists?(override_dir)
    file ::File.join(override_dir, override_file) do
      action :delete
      if new_resource.triggers_reload
        notifies :run, 'fb_systemd_reload[system instance]', :immediately
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
