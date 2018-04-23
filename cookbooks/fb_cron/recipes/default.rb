#
# Cookbook Name:: fb_cron
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require 'shellwords'

case node['platform_family']
when 'mac_os_x'
  svc_name = 'com.vix.cron'
when 'rhel', 'fedora', 'suse'
  package_name = 'vixie-cron'
  if node['platform'] == 'amazon' || node['platform_version'].to_i >= 6
    package_name = 'cronie'
  end
  svc_name = 'crond'
end

if package_name # ~FC023
  package package_name do
    action :upgrade
  end
end

# keep the name 'cron' so we can notify it easily from other places
service 'cron' do
  service_name svc_name
  action [:enable, :start]
end

whyrun_safe_ruby_block 'validate_data' do
  block do
    node['fb_cron']['jobs'].to_hash.each do |name, data|
      if data['only_if']
        unless data['only_if'].class == Proc
          fail 'fb_cron\'s only_if requires a Proc'
        end
        unless data['only_if'].call
          Chef::Log.debug("fb_cron: Not including #{name} due to only_if")
          node.rm('fb_cron', 'jobs', name)
          next
        end
      end
      unless data['command']
        fail "fb_cron entry #{name} lacks a command"
      end
      unless data['time']
        fail "fb_cron entry #{name} lacks a time"
      end

      # If only one instance of this job should be run, add a wrapper script
      # with 'command' as an argument. That code gets eval'd, so you can even
      # use arbitrary bash
      if data['exclusive']
        lockfile = "/tmp/cron-#{name}.lock"
        escaped = Shellwords.shellescape(data['command'])
        command = "/usr/local/bin/exclusive_cron.sh #{lockfile} #{escaped}"
        node.default['fb_cron']['jobs'][name]['command'] = command
      end

      # Calculate a splay that varies across hosts/jobs but is static
      # for each host+job to make debugging easier and stats line up.
      if data['splaysecs']
        if Integer(data['splaysecs']) <= 0 || Integer(data['splaysecs']) > 9600
          fail "unreasonable splaysecs #{data['splaysecs']} in #{name} cron"
        end
        sleepnum = node.get_seeded_flexible_shard(Integer(data['splaysecs']),
                                                  data['command'])
        node.default['fb_cron']['jobs'][name]['splaycmd'] =
          "/bin/sleep #{sleepnum}; "
      else
        node.default['fb_cron']['jobs'][name]['splaycmd'] = ''
      end
    end
  end
end

template 'fb_cron crontab' do
  path lazy {
    node['fb_cron']['_crontab_path']
  }
  source 'fb_crontab.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/anacrontab' do
  only_if { node['platform_family'] == 'rhel' }
  source 'anacrontab.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

envfile = value_for_platform_family(
  'debian' => '/etc/default/cron',
  ['rhel', 'fedora'] => '/etc/sysconfig/crond',
)
if envfile # ~FC023
  template envfile do
    source 'crond_env.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[cron]'
  end
end

# Cleanup rpmnew and rpmsave files
Dir.glob('/etc/cron*/*.rpm{save,new}').each do |todel|
  file todel do
    action :delete
  end
end

# Make sure we nuke all crons from the cron resource.
root_crontab = value_for_platform_family(
  ['rhel', 'fedora', 'suse'] => '/var/spool/cron/root',
  ['debian', 'ubuntu'] => '/var/spool/cron/crontabs/root',
)
if root_crontab
  file 'clean out root crontab' do
    path root_crontab
    action :delete
  end
end

cookbook_file '/usr/local/bin/exclusive_cron.sh' do
  source 'exclusive_cron.sh'
  owner 'root'
  group 0
  mode '0755'
end

if node.macosx?
  cookbook_file '/usr/local/bin/osx_make_crond.sh' do
    source 'osx_make_crond.sh'
    owner 'root'
    group 0
    mode '0755'
  end

  execute 'osx_make_crond.sh' do
    command '/usr/local/bin/osx_make_crond.sh'
  end
end
