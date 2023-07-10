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

property :version, :kind_of => String

load_current_value do
  extend FB::Choco::Helpers
  begin
    choco_exe = get_choco_bin
    fail if choco_exe.nil?
    ver = Mixlib::ShellOut.new("#{choco_exe} --version")
    choco_version = ver.run_command.stdout.chomp
    fail if choco_version.empty?
  rescue StandardError => e
    Chef::Log.warn(
      "fb_choco: Chocolatey executable was not found due to error:#{e.message}",
    )
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

  if current_version != FB::Version.new('0.0.0')
    # A verson of choco is already installed. We don't need the correct version
    # installed as we will use the installed version to upgrade us to desired.
    Chef::Log.debug('[fb_choco] Chocolatey already bootstrapped. Skipping...')
    return
  end

  Chef::Log.debug('[fb_choco] Chocolatey is not installed. Bootstrapping...')

  converge_by("Installing chocolatey v#{desired_version}") do
    # If chocolatey doesn't exist, use the script
    run_bootstrap_script
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

    cookbook_file 'chocolatey_install script' do
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
