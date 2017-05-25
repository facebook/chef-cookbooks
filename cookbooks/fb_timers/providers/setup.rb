# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

def whyrun_supported?
  true
end

use_inline_resources

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
