# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2013-present, Facebook, Inc.
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

resource_name :fb_helpers_reboot

provides :fb_helpers_reboot, :os => ['darwin', 'linux']

# description 'Use the fb_helpers_reboot resource if you need to indicate to an'
#             ' external service that the host needs to be rebooted and when'
#             ' that reboot action should be handled.'

default_action :now

property :required, [true, false],
         :default => true
#         :description => 'Control whether the Chef run should fail until the '
#                         'host has been rebooted successfully.'

property :wakeup_time_secs, Integer,
         :default => 120
#         :description => 'The number of seconds we should wait before waking '
#                         'the system back up using the RTC.'

property :__fb_helpers_internal_allow_process_deferred, [true, false],
         :default => false
#         :description => 'Internal property; :process_deferred will fail '
#                         'unless this is set to true to prevent accidental '
#                         'misuse.'

property :prefix, ['/tmp', '/dev/shm']
#         :description => 'Directory prefix for the reboot flag files; used '
#                         'only via load_current_value'

# Signals future chef-client runs to abort until after reboot
REBOOT_OVERRIDE = 'chef_reboot_override'.freeze

# Signals :process_deferred that there are reboots enqueued.
REBOOT_TRIGGER = 'chef_reboot_trigger'.freeze

# Signals :process_deferred that it should fail the run if it can't reboot
REBOOT_REQUIRED = 'chef_reboot_required'.freeze

NOT_ALLOWED_MSG = 'Was asked to reboot, but ' +
                  "node['fb_helpers']['reboot_allowed'] is false!".freeze

load_current_value do
  # macOS doesn't have /dev/shm, so use /tmp instead which is wiped on boot.
  prefix node.macos? ? '/tmp' : '/dev/shm'
end

action_class do
  def load_reboot_reason
    reason = 'not specified'
    if ::File.exist?(::File.join(current_resource.prefix, REBOOT_OVERRIDE))
      reason =
        ::File.read(::File.join(current_resource.prefix, REBOOT_OVERRIDE)).chomp
    end
    reason
  end

  def set_reboot_override(reboot_type)
    unless reboot_type
      fail 'set_reboot_override: reboot_type was not set, aborting!'
    end

    file ::File.join(current_resource.prefix, REBOOT_OVERRIDE) do
      owner 'root'
      group 'root'
      mode '0644'
      content "#{reboot_type} reboot '#{new_resource.name}' requested by " +
        "recipe #{cookbook_name}::#{new_resource.recipe_name}"
    end
  end

  def set_reboot_trigger
    file ::File.join(current_resource.prefix, REBOOT_TRIGGER) do
      owner 'root'
      group 'root'
      mode '0644'
    end
  end

  def set_reboot_required
    file ::File.join(current_resource.prefix, REBOOT_REQUIRED) do
      owner 'root'
      group 'root'
      mode '0644'
    end
  end

  def do_managed_reboot
    msg = '*** Reboot required to proceed'

    node['fb_helpers']['managed_reboot_callback']&.call(node)

    ruby_block 'Managed reboot' do
      block do
        fail msg
      end
      action :nothing
    end

    ruby_block 'Schedule failure for reboot' do
      block {}
      notifies :run, 'ruby_block[Managed reboot]'
    end
  end
end

action :now do
  # TODO (t15830562) - this action should observe required and override the
  # same way as the :deferred action
  if node['fb_helpers']['reboot_allowed']
    if node.firstboot_any_phase?
      set_reboot_override('immediate')
      do_managed_reboot
    else
      command = execute 'reboot' do # ~FB026
        command 'reboot'
        action :nothing
      end

      node['fb_helpers']['reboot_logging_callback']&.call(
        node,
        "reboot reason: '#{new_resource.name}' requested by " +
        "recipe #{cookbook_name}::#{new_resource.recipe_name}",
      )
      command.run_action(:run)
      fail 'Reboot requested, aborting chef run and rebooting'
    end
  elsif new_resource.required
    fail NOT_ALLOWED_MSG
  else
    Chef::Log.error(NOT_ALLOWED_MSG)
  end
end

action :managed_now do
  if node.firstboot_any_phase?
    set_reboot_override('managed')
    do_managed_reboot
  else
    Chef::Log.info('Managed reboot supported only during provisioning')
  end
end

action :deferred do
  set_reboot_trigger

  if new_resource.required
    # If a reboot is required, Chef will persistently fail Chef until the
    # reboot happens.
    set_reboot_override('deferred')
    set_reboot_required
  end
end

# This is an internal action that's only used at the end of fb_init to collate
# and synchronize all the reboot requests.
action :process_deferred do
  unless new_resource.__fb_helpers_internal_allow_process_deferred
    fail 'You didn\'t say the magic word...'
  end

  # TODO do we need another flag file for this? or can we use REBOOT_OVERRIDE?
  if ::File.exist?(::File.join(current_resource.prefix, REBOOT_TRIGGER))
    if node.firstboot_any_phase?
      set_reboot_override('process_deferred')
      do_managed_reboot
    elsif ::File.exist?(::File.join(current_resource.prefix, REBOOT_REQUIRED))
      if node['fb_helpers']['reboot_allowed']
        node['fb_helpers']['reboot_logging_callback']&.call(
          node,
          load_reboot_reason,
        )
        reboot 'reboot' do # ~FB026
          action :request_reboot
        end
      else
        fail NOT_ALLOWED_MSG
      end
    else
      Chef::Log.info('Reboot requested, but not required. Chef will succeed,' +
                     ' but host is pending reboot by an external entity.')
    end
  else
    Chef::Log.info('Trigger not found, no reboots to process')
  end
end

action :rtc_wakeup do
  message = 'RTC can wake'
  verify_rtc_cap = execute 'verify_rtc_cap' do
    # Sometimes the RTC message has fallen out of `dmesg`, but it's still
    # in /var/log/dmesg. So check both if we have to.
    command "grep -q '#{message}' /var/log/dmesg 2>/dev/null || " +
            "dmesg | grep -q '#{message}'"
    action :nothing
  end
  set_wakeup = execute 'set_wakeup' do
    command "rtcwake -m no -s #{new_resource.wakeup_time_secs}"
    action :nothing
  end
  poweroff = execute 'poweroff' do # ~FB026
    command 'shutdown -P now'
    action :nothing
  end

  if node.firstboot_any_phase?
    Chef::Log.info('Not rebooting because we are in firstboot')
  elsif node['fb_helpers']['reboot_allowed']
    set_reboot_override('rtc_wakeup')

    verify_rtc_cap.run_action(:run)
    set_wakeup.run_action(:run)
    node['fb_helpers']['reboot_logging_callback']&.call(
      node,
      "poweroff reason: '#{new_resource.name}' (#{message}) requested by " +
        "recipe #{cookbook_name}::#{new_resource.recipe_name}",
      'poweroff',
    )
    poweroff.run_action(:run)
    fail "Hard shutdown requested, aborting chef and shutting down.
          Server should wake up in #{new_resource.wakeup_time_secs} seconds."
  else
    fail NOT_ALLOWED_MSG
  end
end
