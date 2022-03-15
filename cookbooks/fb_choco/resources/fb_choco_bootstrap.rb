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
# Cookbook Name:: fb_choco
# Resource:: fb_choco_bootstrap

resource_name :fb_choco_bootstrap
provides :fb_choco_bootstrap
default_action :install
unified_mode true

property :version, :kind_of => String

load_current_value do
  extend Chef::Mixin::Which
  choco_exe = which('choco.exe')
  ver = Mixlib::ShellOut.new("#{choco_exe} --version")
  begin
    choco_version = ver.run_command.stdout.chomp
    fail if choco_version.empty?
  rescue StandardError
    Chef::Log.warn('fb_choco: Chocolatey executable was not found!')
    choco_version = '0.0.0'
  end
  set_or_return(:version, choco_version, {})
end

action :install do
  unless node.windows?
    fail "fb_choco: Chocolatey is not supported on #{node['os']}."
  end

  current_version = FB::Version.new(current_resource.version)
  desired_version = FB::Version.new(new_resource.version)

  case current_version <=> desired_version
  when -1
    # Higher version
    Chef::Log.debug('[fb_choco] Current version is older. Upgrading...')
  when 0
    # Same version
    Chef::Log.debug('[fb_choco] Chocolatey is current, nothing to do.')
    return
  when 1
    # Lower version
    # Upgrade should not try to install older versions.
    Chef::Log.warn(
      "[fb_choco] Chocolatey #{desired_version} is older than what is " +
      "installed (#{current_version}). Downgrading...",
    )
  else # Only alternative is nil
    # Nil is returned if comparison was not with a version.
    fail(
      '[fb_choco] Version comparisons failed! Current: ' +
      "#{current_resource.version}, Desired: #{new_resource.version}",
    )
  end

  converge_by("Installing chocolatey v#{desired_version}") do
    if current_version == FB::Version.new('0.0.0')
      # If chocolatey doesn't exist, use the script
      run_bootstrap_script
    else
      # Chocolatey exists. Let's use built in upgrade mechanism
      chocolatey_package 'chocolatey' do
        action :upgrade
        version node['fb_choco']['bootstrap']['version']
        options '--allow-downgrade'
      end
    end
  end
end

action_class do
  def run_bootstrap_script
    choco_install_ps1 = ::File.join(
      Chef::Config['file_cache_path'], 'choco_bootstrap.ps1'
    )
    bootstrap_vars = {
      'chocolateyDownloadUrl' =>
        node['fb_choco']['bootstrap']['choco_download_url'],
      'chocolateyUseWindowsCompression' =>
        node['fb_choco']['bootstrap']['use_windows_compression'].to_s,
    }

    cookbook_file 'chocolatey_install script' do # ~FB031
      path choco_install_ps1
      source 'choco_install/install.ps1'
      owner 'Administrators'
      rights :read, 'Users'
      rights :full_control, 'Administrators'
      group node.root_group
    end

    powershell_script 'chocolatey_install' do
      code choco_install_ps1
      environment bootstrap_vars
      action :run
    end
  end
end
