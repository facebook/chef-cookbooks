# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

def whyrun_supported?
  true
end

action :run do
  # Delete old jobs
  Dir.glob("#{node['fb_timers']['_timer_path']}/*").each do |path|
    # this doubles as the unit name.
    fname = ::File.basename(path)

    # This is managed by the cookbook, skip it.
    next if fname == 'README'

    # Don't delete any directories
    next if ::File.directory?(path)

    exp = /^([\w:-]+)\.(service|timer)$/
    m = exp.match(fname)
    if m
      name = m[1]
      type = m[2]
      next if node['fb_timers']['jobs'].to_hash.key?(name)
    end

    # If there's a link in systemd's unit path, delete it too
    # We have to do this first cause you can't disable a unit who's file has
    # disappeared off the filesystem
    possible_link = "/etc/systemd/system/#{fname}"
    if ::File.symlink?(possible_link) && # ~FC023
      ::File.readlink(possible_link) == path
      # systemd can get confused if you delete the file without disabling
      # the unit first. Disabling a linked unit removes the symlink anyway.
      service fname do
        action [:disable, :stop]
      end
    end

    Chef::Log.warn("fb_timers: Removing unknown #{type} file #{path}")
    file path do
      action :delete
    end
  end

  # Setup current jobs
  node['fb_timers']['jobs'].to_hash.each_pair do |name, conf|
    conf = FB::Systemd::TIMER_DEFAULTS.merge(conf.merge('name' => name))

    # Do this early so we can rely on commands being filled in
    if conf['command']
      if conf['commands']
        Chef::Log.warn("fb_timers: [#{conf['name']}] You shouldn't mix " +
                       '`command` and `commands`')
      else
        conf['commands'] = []
      end
      conf['commands'] << conf['command']
    end

    unknown_keys = conf.keys - FB::Systemd::TIMER_COOKBOOK_KEYS
    if unknown_keys.any?
      Chef::Log.warn(
        "fb_timers: Unknown keys for timer #{name}: #{unknown_keys}",
      )
      if unknown_keys.find { |key| key.casecmp('user').zero? }
        Chef::Log.warn('fb_timers: To set a user ' +
                       "{ 'timer_options' => {'User' => 'nobody' }")
      end
    end

    missing_keys = FB::Systemd::REQUIRED_TIMER_KEYS - conf.keys
    if missing_keys.include?('calendar')
      # calendar is not entirely mandatory, one can use On...
      unless (conf['timer_options'].keys &
        FB::Systemd::ALTERNATE_CALENDAR_KEYS).empty?
        missing_keys.delete('calendar')
      end
    end
    if missing_keys.any?
      fail "fb_timers: Missing required key for timer #{name}: #{missing_keys}"
    end

    if conf['only_if']
      unless conf['only_if'].class == Proc
        fail 'fb_timers\'s only_if requires a Proc'
      end

      unless conf['only_if'].call
        Chef::Log.debug("fb_timers: Not including #{conf['name']}" +
                        'due to only_if')
        node.rm('fb_timers', 'jobs', conf['name'])
        next
      end
    end

    %w{service timer}.each do |type|
      filename = "#{node['fb_timers']['_timer_path']}/#{conf['name']}.#{type}"
      template filename do
        source "#{type}.erb"
        mode '0644'
        owner 'root'
        group 'root'
        # Use of variables within templates is heavily discouraged.
        # It's safe to use here since it's in a provider and isn't used
        # directly.
        variables :conf => conf
        notifies :run, 'fb_systemd_reload[system instance]', :immediately
      end

      execute "link unit file #{filename}" do
        not_if do
          ::File.exist?("/etc/systemd/system/#{conf['name']}.#{type}") ||
            !conf['autostart']
        end
        command "systemctl link #{filename}"
        notifies :run, 'fb_systemd_reload[system instance]', :immediately
      end
    end

    service "#{conf['name']}.timer" do
      only_if { conf['autostart'] }
      action [:enable, :start]
    end
  end

  # Delete any dead symlinks to timers within /etc/systemd/system
  dead_links = Dir.glob("#{FB::Systemd::UNIT_PATH}/*").select do |unit|
    # only delete symlinks
    ::File.symlink?(unit) &&
      # whose targets are timer files
      ::File.readlink(unit).start_with?(node['fb_timers']['_timer_path']) &&
      # whose targets don't exist
      !::File.exist?(::File.readlink(unit))
  end
  dead_links.each do |unit|
    Chef::Log.warn("fb_timers: Removing dead link #{unit}")
    # we can't use systemctl disable here because it's already deleted
    link unit do
      action :delete
    end
  end
end
