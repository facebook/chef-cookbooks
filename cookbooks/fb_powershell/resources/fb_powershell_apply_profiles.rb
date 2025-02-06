# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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
#

resource_name :fb_powershell_apply_profiles
provides :fb_powershell_apply_profiles, :os => 'windows'
unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
provides :fb_powershell_apply_profiles, :os => 'darwin'
provides :fb_powershell_apply_profiles, :os => 'linux'

default_action :manage

property :powershell_core, [true, false], :default => true
action :manage do
  profiles = [
    'AllUsersAllHosts',
    'AllUsersCurrentHost',
    'CurrentUserAllHosts',
    'CurrentUserCurrentHost',
  ].freeze

  profiles.each do |profile|
    if node['fb_powershell']['profiles'][profile].nil?
      log "No profile content set for #{profile}. Skipping..."
      next
    elsif node['fb_powershell']['profiles'][profile].is_a?(Array)
      content = node['fb_powershell']['profiles'][profile].join("\n")
    else
      content = node['fb_powershell']['profiles'][profile]
    end

    if new_resource.powershell_core
      # Determine the appropriate paths
      install_paths = install_pwsh_path_list(node)
      install_paths.each do |install_path|
        path = get_profile_path(
          profile,
          install_path,
          new_resource.powershell_core,
        )

        # Manage file
        file path do
          content content
          if platform?('windows')
            rights :full_control, ['Administrators', 'SYSTEM']
            rights :read, 'Users'
          else
            owner node.root_user
            group node.root_group
            mode '0744'
          end
        end
      end
    else
      path = get_profile_path(
        profile,
        nil,
        new_resource.powershell_core,
      )

      # Manage file
      file path do
        content content
        if platform?('windows')
          rights :full_control, ['Administrators', 'SYSTEM']
          rights :read, 'Users'
        else
          owner node.root_user
          group node.root_group
          mode '0744'
        end
      end
    end
  end
end

action_class do
  include FB::PowerShell
end
