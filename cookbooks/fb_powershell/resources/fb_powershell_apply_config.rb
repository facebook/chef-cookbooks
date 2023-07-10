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

resource_name :fb_powershell_apply_config
provides :fb_powershell_apply_config, :os => 'windows'
provides :fb_powershell_apply_config, :os => 'darwin'
provides :fb_powershell_apply_config, :os => 'linux'

default_action :manage

action :manage do
  install_paths = install_pwsh_path_list(node)
  install_paths.each do |install_path|
    path = ::File.join(install_path, 'powershell.config.json')
    template path do
      only_if { node['fb_powershell']['manage_config'] }
      source 'powershell.config.json.erb'
      if platform?('windows')
        rights :full_control, ['Administrators', 'SYSTEM']
        rights :read, 'Users'
      else
        owner node.root_user
        group node.root_group
        mode '0744'
      end
      action :create
    end
  end
end

action_class do
  include FB::PowerShell
end
