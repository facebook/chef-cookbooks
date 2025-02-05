# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2021-present, Facebook, Inc.
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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :run

action :run do
  log = node['fb_system_upgrade']['log']

  # We don't want this cookbook to take a dependency on fb_dnf_settings,
  # so check if it's loaded in the run.
  fb_dnf_settings = FB.const_defined?(:DnfSettings)

  ruby_block 'optionally enable rou repos' do
    # Restore ROU repos before the upgrade and swap resources below.
    block do
      if fb_dnf_settings && node['fb_dnf_settings']['disable_default_rou_repos']
        FB::DnfSettings.update_dnf_conf(node, false)
      end
    end
  end

  to_upgrade = []
  node['fb_system_upgrade']['early_upgrade_packages'].each do |p|
    if node.rpm_version(p)
      to_upgrade << p
    end
  end

  unless to_upgrade.empty?
    Chef::Log.info("fb_system_upgrade: early upgrade for #{to_upgrade}")
    package to_upgrade do
      action :upgrade
    end
  end

  to_remove = node['fb_system_upgrade']['early_remove_packages']
  unless to_remove.empty?
    Chef::Log.info("fb_system_upgrade: early remove for #{to_remove}")
    package to_remove do
      action :remove
    end
  end

  node['fb_system_upgrade']['early_swap_packages'].to_hash.each do |old, new|
    execute "swap #{old} with #{new}" do
      command FB::SystemUpgrade.get_swap_command(node, old, new)
    end
  end

  cmd = FB::SystemUpgrade.get_upgrade_command(node)

  ruby_block 'actual_dnf_upgrade' do
    block do
      Chef::Log.info("fb_system_upgrade: Actual upgrade command: #{cmd}")
      s = Mixlib::ShellOut.new(
        cmd,
        :timeout => node['fb_system_upgrade']['timeout'],
      ).run_command
      if fb_dnf_settings && node['fb_dnf_settings']['disable_default_rou_repos']
        # Disable ROU repos before reporting success / failure.
        FB::DnfSettings.update_dnf_conf(node)
      end
      if s.exitstatus.zero?
        if node['fb_system_upgrade']['success_callback_method']
          Chef::Log.info('fb_system_upgrade: Running success callback')
          begin
            node['fb_system_upgrade']['success_callback_method'].call(node)
          rescue StandardError => e
            # It's critical we don't fail the run here if the upgrade itself
            # succeeded
            Chef::Log.warn(
              'fb_system_upgrade: success callback failed in some unexpected ' +
              "way: #{e.inspect}",
            )
            next true
          end
        end
      else
        if node['fb_system_upgrade']['failure_callback_method']
          Chef::Log.info('fb_system_upgrade: Running failure callback')
          node['fb_system_upgrade']['failure_callback_method'].call(node)
        end
        # Ideally we'd just 'next false' here so that we see the resource
        # failed without having to throw a stracktrace, but that doesn't work
        # anymore (https://github.com/chef/chef/issues/3465)
        msg = "fb_system_upgrade: OS Upgrade failed\n" +
              "#{s.format_for_exception}\n\n" +
              "\t*****************************\n\tSEE LOG: #{log}\n"
        fail msg
      end
    end
    node['fb_system_upgrade']['notify_resources_before'].each do |my_r, my_a|
      notifies my_a, my_r, :before
    end
    node['fb_system_upgrade']['notify_resources'].each do |my_r, my_a|
      notifies my_a, my_r
    end
  end
end
