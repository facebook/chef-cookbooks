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
    owner 'root'
    group 'root'
  end
  return
end

# assume linux from here onwards

include_recipe 'fb_logrotate::packages'

whyrun_safe_ruby_block 'munge logrotate configs' do
  block do
    node['fb_logrotate']['configs'].to_hash.each do |name, block|
      if block['overrides']
        if block['overrides']['rotation'] == 'weekly' &&
           !block['overrides']['rotate']
          node.default['fb_logrotate']['configs'][name][
            'overrides']['rotate'] = '4'
        end
        if block['overrides']['size']
          time = "size #{block['overrides']['size']}"
        elsif %w{hourly weekly monthly yearly}.include?(
          block['overrides']['rotation'],
        )
          time = block['overrides']['rotation']
        end
      end
      if time
        node.default['fb_logrotate']['configs'][name]['time'] = time
      end
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
  owner 'root'
  group 'root'
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
    owner 'root'
    group 'root'
    notifies :run, 'execute[logrotate reload systemd]', :immediately
  end

  # Create systemd timer
  template timer_logrotate do
    source 'logrotate.timer.erb'
    mode '0644'
    owner 'root'
    group 'root'
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
      owner 'root'
      group 'root'
    end
  else
    # Fall back to the job RPM comes with CentOS7 RPM
    cookbook_file cron_logrotate do
      source 'logrotate.cron.daily'
      owner 'root'
      group 'root'
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

# syslog has been moved into the main fb_logrotate.conf
# CentOS and Debian use different files for their main syslog configuration
syslog_config = value_for_platform_family(
  ['rhel', 'fedora'] => '/etc/logrotate.d/syslog',
  'debian' => '/etc/logrotate.d/rsyslog',
)

file syslog_config do
  action 'delete'
end
