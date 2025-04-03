#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

action :setup do
  sysconfig_path = if ChefUtils.fedora_derived?
                     '/etc/sysconfig'
                   else
                     '/etc/default'
                   end
  node['fb_openport']['config']['sessions'].each do |port, config|
    name = "openport-#{port}"
    svc = "openport@#{port}"
    if config['options']
      template ::File.join(sysconfig_path, name) do
        owner node.root_user
        group node.root_group
        mode '0644'
        source 'sysconfig.erb'
        variables({ 'instance' => port })
        notifies :restart, "service[#{svc}]"
      end
    end

    with_run_context :root do
      service svc do
        action [:enable, :start]
      end
    end
  end

  s = Mixlib::ShellOut.new(
    ['systemctl', 'list-units', '-a', 'openport@*', '-o', 'json'],
  ).run_command
  s.error!
  instances = JSON.parse(s.stdout)
  instances.each do |instance|
    m = instance['unit'].match('openport@(\d+).service')
    port = m[1]
    next if node['fb_openport']['config']['sessions'][port]

    service instance['unit'] do
      action [:stop, :disable]
    end
  end
  ::Dir.glob("#{sysconfig_path}/openport-*").each do |f|
    fname = ::File.basename(f)
    port = fname.split('-', 2).last
    next if node['fb_openport']['config']['sessions'][port]

    file f do
      action :delete
    end
  end
end

action :restart do
  notify_group 'restart all openport instances' do
    node['fb_openport']['config']['sessions'].each_key do |port|
      notifies :restart, "service[openport@#{port}]"
    end
    action :run
  end
end
