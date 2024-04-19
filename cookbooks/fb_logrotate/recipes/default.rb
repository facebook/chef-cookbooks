#
# Cookbook Name:: fb_logrotate
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

if node.macos?
  template '/etc/newsyslog.d/fb_bsd_newsyslog.conf' do
    source 'fb_bsd_newsyslog.conf.erb'
    mode '0644'
    owner node.root_user
    group node.root_group
  end
  return
end

# assume linux from here onwards

include_recipe 'fb_logrotate::packages'

whyrun_safe_ruby_block 'munge logrotate configs' do
  block do
    globals = node['fb_logrotate']['globals'] # Keep globals out of loop below to avoid deep merge cache flap
    node['fb_logrotate']['configs'].to_hash.each do |name, block|
      config = block.dup
      time = nil
      if config['overrides']
        rotation = config['overrides']['rotation']
        size = config['overrides']['size']

        if rotation && size
          fail "fb_logrotate:[#{name}]: you can only use size or rotation " +
            'not both'
        end

        if rotation
          # if someone wants to override weekly but didn't specify
          # how many to keep, we default to 4
          if rotation == 'weekly' && !config['overrides']['rotate']
            config['overrides']['rotate'] = '4'
          end

          if %w{hourly daily weekly monthly yearly}.include?(rotation)
            time = rotation
            config['overrides']['rotation'] = nil
          else
            fail "fb_logrotate:[#{name}]: rotation #{rotation} invalid"
          end
        end

        if size
          time = "size #{size}"
          config['overrides']['size'] = nil
        end

        if config['overrides']['nocompress'] && globals['nocompress']
          # redundant, remove
          config['overrides']['nocompress'] = nil
        end
      end
      if time
        config['time'] = time
      end
      node.default['fb_logrotate']['configs'][name] = config
    end
  end
end

whyrun_safe_ruby_block 'validate logrotate configs' do
  block do
    files = []
    node['fb_logrotate']['configs'].to_hash.each_value do |block|
      files += block['files']
    end
    if files.uniq.length < files.length
      fail 'fb_logrotate: there are duplicate logrotate configs!'
    else
      dfiles = []
      tocheck = []
      files.each do |f|
        if f.end_with?('*')
          dfiles << ::File.dirname(f)
        else
          tocheck << f
        end
      end
      tocheck.each do |f|
        if dfiles.include?(::File.dirname(f))
          fail "fb_logrotate: there is an overlapping logrotate config for #{f}"
        end
      end
    end
  end
end

template '/etc/logrotate.d/fb_logrotate.conf' do
  source 'fb_logrotate.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
end

cron_logrotate = '/etc/cron.daily/logrotate'
service_logrotate = '/etc/systemd/system/logrotate.service'
timer_name = 'logrotate.timer'
timer_logrotate = "/etc/systemd/system/#{timer_name}"

execute 'logrotate reload systemd' do
  command '/bin/systemctl daemon-reload'
  action :nothing
  only_if { node.systemd? }
end

if node['fb_logrotate']['systemd_timer'] && node.systemd?
  # Use systemd timer
  # Create systemd service
  template service_logrotate do
    source 'logrotate.service.erb'
    mode '0644'
    owner node.root_user
    group node.root_group
    notifies :run, 'execute[logrotate reload systemd]', :immediately
  end

  # Create systemd timer
  template timer_logrotate do
    source 'logrotate.timer.erb'
    mode '0644'
    owner node.root_user
    group node.root_group
    notifies :run, 'execute[logrotate reload systemd]', :immediately
  end

  # Enable logrotate timer
  systemd_unit timer_name do
    action [:enable, :start]
  end

  # Remove cron job
  file cron_logrotate do
    action :delete
  end
else
  if node['fb_logrotate']['add_locking_to_logrotate']
    # If cron should be used, and `add_locking_to_logrotate` opted in, generate
    # Cron job with locking
    template cron_logrotate do
      source 'logrotate_rpm_cron_override.erb'
      mode '0755'
      owner node.root_user
      group node.root_group
    end
  else
    # Fall back to the job RPM comes with CentOS7 RPM
    cookbook_file cron_logrotate do
      source 'logrotate.cron.daily'
      owner node.root_user
      group node.root_group
      mode '0755'
      action :create
    end
  end

  file service_logrotate do
    action :delete
    notifies :run, 'execute[logrotate reload systemd]', :immediately
  end

  file timer_logrotate do
    action :delete
    notifies :run, 'execute[logrotate reload systemd]', :immediately
  end
end

if node.centos9? || node.fedora38? || node.fedora39?
  # This was a separate package but it's been subsumed again
  # https://bugzilla.redhat.com/show_bug.cgi?id=2242243
  # https://bugzilla.redhat.com/show_bug.cgi?id=1992153
  package 'rsyslog-logrotate' do
    action :remove
  end
else
  # On all other systems the config is part of the main rsyslog package and
  # needs to be clobbered directly. Note that CentOS and Debian use different
  # files for their main syslog configuration.
  syslog_config = value_for_platform_family(
    ['rhel', 'fedora'] => '/etc/logrotate.d/syslog',
    'debian' => '/etc/logrotate.d/rsyslog',
  )

  # We want to manage the rsyslog logrotate config with fb_logrote so we
  # remove the one installed by the system package.
  file syslog_config do
    action 'delete'
  end
end
