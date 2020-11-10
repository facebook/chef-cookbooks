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

module FB
  module PowerShell
    def install_pwsh_path_list
      platform = node['platform']
      case platform
      when 'windows'
        get_windows_pwsh_paths
      when 'centos'
        get_linux_pwsh_paths
      when 'mac_os_x'
        get_darwin_pwsh_paths
      else
        fail "fb_powershell: not supported #{platform} os"
      end
    end

    def get_windows_pwsh_paths
      core_path = Chef::Util::PathHelper.escape_glob_dir(
        File.join(ENV['ProgramFiles'], 'PowerShell'),
      )
      paths = Dir.glob(core_path + '/[6789]*')
      return paths
    end

    def get_linux_pwsh_paths
      # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
      paths = Dir.glob('/opt/microsoft/powershell/[6789]*')
      return paths
    end

    def get_darwin_pwsh_paths
      # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos
      paths = Dir.glob('/usr/local/microsoft/powershell/[6789]*')
      return paths
    end

    def get_profile_path(profile, install_path, core)
      if platform?('windows')
        if core
          get_profile_path_windows_core(profile, install_path)
        else
          get_profile_path_windows(profile)
        end
      else
        get_profile_path_non_windows(profile, install_path)
      end
    end

    def get_profile_path_windows(profile)
      case profile
      when 'AllUsersAllHosts'
        'C:/Windows/System32/WindowsPowerShell/v1.0/profile.ps1'
      when 'AllUsersCurrentHost'
        'C:/Windows/System32/WindowsPowerShell/v1.0/Microsoft.PowerShell' +
        '_profile.ps1'
      when 'CurrentUserAllHosts'
        '~/Documents/WindowsPowerShell/profile.ps1'
      when 'CurrentUserCurrentHost'
        '~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1'
      else
        fail 'Passed an invalid path'
      end
    end

    def get_profile_path_windows_core(profile, install_path)
      case profile
      when 'AllUsersAllHosts'
        "#{install_path}/profile.ps1"
      when 'AllUsersCurrentHost'
        "#{install_path}/Microsoft.PowerShell_profile.ps1"
      when 'CurrentUserAllHosts'
        '~/Documents/PowerShell/profile.ps1'
      when 'CurrentUserCurrentHost'
        '~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
      else
        fail 'Passed an invalid path'
      end
    end

    def get_profile_path_non_windows(profile, install_path)
      case profile
      when 'AllUsersAllHosts'
        "#{install_path}/profile.ps1"
      when 'AllUsersCurrentHost'
        "#{install_path}/Microsoft.PowerShell_profile.ps1"
      when 'CurrentUserAllHosts'
        '~/.config/powershell/powershell/profile.ps1'
      when 'CurrentUserCurrentHost'
        '~/.config/powershell/Microsoft.PowerShell_profile.ps1'
      else
        fail 'Passed an invalid path'
      end
    end
  end
end
