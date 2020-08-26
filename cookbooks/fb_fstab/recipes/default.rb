#
# Cookbook Name:: fb_fstab
# Recipe:: default
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
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#

# This will conditionally generate our base file if we need to.
# We do this at compile time on purpose... nice and early.
FB::Fstab.generate_base_fstab

# ensure permissions
file FB::Fstab::BASE_FILENAME do
  owner 'root'
  group 'root'
  mode '0444'
end

# We fill in defaults for most stuff if you don't specify, but there are a few
# basic things we need
whyrun_safe_ruby_block 'validate data' do
  block do
    uniq_devs = {}
    node['fb_fstab']['mounts'].to_hash.each do |name, data|
      # Handle only_if
      if data['only_if']
        unless data['only_if'].respond_to?(:call)
          fail 'fb_fstab\'s only_if requires a Proc'
        end

        unless data['only_if'].call
          Chef::Log.debug("fb_fstab: Not including #{name} due to only_if")
          node.rm('fb_fstab', 'mounts', name)
          next
        end
      end

      # Add a default for non-required fields
      unless data['opts']
        node.default['fb_fstab']['mounts'][name]['opts'] = 'rw'
      end
      unless data['type']
        node.default['fb_fstab']['mounts'][name]['type'] = 'auto'
      end

      # Enforce required fields
      %w{mount_point device}.each do |req_field|
        unless data[req_field]
          fail "No #{req_field} provided for #{name}"
        end
      end

      # Sanity checks
      if data['device'] == 'tmpfs' && data['mount_point'] != '/dev/shm'
        fail 'Using "tmpfs" as a device for non-/dev/shm is no longer ' +
          'supported. Please use a meaningful name - the fstype will be ' +
          'enough to tell the kernel it is tmpfs. Offending mount: ' +
          "#{data['mount_point']}."
      end
      is_bind_mount = false
      is_systemd_automount = false
      if data['opts']
        opt_list = data['opts'].split(',')
        is_bind_mount = opt_list.include?('bind')
        is_systemd_automount = opt_list.include?('x-systemd.automount')
      end
      unless ['nfs', 'nfs4', 'glusterfs', 'nfusr'].include?(
        data['type'],
      ) || is_bind_mount
        if uniq_devs[data['device']] &&
          !FB::Fstab.btrfs_subvol?(data['type'], data['opts'])
          fail 'Device names must be unique and you have repeated ' +
            "#{data['device']} for #{uniq_devs[data['device']]} and " +
            "#{data['mount_point']}. If this is a tmpfs or other virtual " +
            'filesystem, please use descriptive unique names.'
        end
        uniq_devs[data['device']] = data['mount_point']
      end

      # Handle dumb
      auto = FB::Fstab.autofs_parent(data['mount_point'], node)
      if auto && !is_systemd_automount
        fail "fb_fstab: Refusing to mount '#{name}' because the mount point " +
          "(#{data['mount_point']}) is within an autofs controlled directory" +
          " #{auto}"
      end
    end
  end
end

execute 'fb_fstab-daemon-reload' do
  command '/bin/systemctl daemon-reload'
  action :nothing
end

template '/etc/fstab' do
  source 'fstab.erb'
  owner 'root'
  group 'root'
  mode '0644'
  # On systemd hosts we use the generated mount units to mount filesystems
  # so it's important we ask it to regenerate them when we edit fstab
  if node.systemd?
    notifies :run, 'execute[fb_fstab-daemon-reload]', :immediately
  end
end

fb_fstab 'handle_mounts'
