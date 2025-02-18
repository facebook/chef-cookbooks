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

property :zones_dir, String, :required => true
property :group, String, :required => true

action :run do
  node['fb_bind']['zones'].each do |name, info|
    if info['type'] != 'primary'
      Chef::Log.debug(
        "fb_bind[#{name}]: Not generating zonefile for type #{info['type']}",
      )
      next
    end

    zf_path = "#{new_resource.zones_dir}/primary/db.#{name}"
    if info['_zonefile_cookbook']
      cookbook zf_path do
        cookbook info['_zonefile_cookbook']
        owner node.root_group
        group new_resource.group
        mode '0644'
        verify "named-checkzone #{name} %{path}"
      end
    else
      template zf_path do
        owner node.root_group
        group new_resource.group
        mode '0644'
        variables({ :zone => name })
        source 'zonefile.erb'
        verify "named-checkzone #{name} %{path}"
      end
    end
  end

  # gather a list of zonefiles to possible remove...
  files = Dir.glob("#{new_resource.zones_dir}/primary/*")

  # Exclude zonefiles for zones we own
  #
  # We this before adding configs to consider for removal below
  # because we want to cleanup errant zonefiles in the wrong directory
  # (if cleanup in config dirs was enabled)
  files.reject! do |f|
    zone = ::File.basename(f).gsub(/^db\./, '').
           gsub(/\.(jbk|jnl|signed|signed.jnl)$/, '')
    node['fb_bind']['zones'].key?(zone)
  end

  # Optionally add configs...
  if node['fb_bind']['clean_config_dir']
    files += Dir.glob("#{FB::Bind::CONFIG_DIR}/*")
  end

  # Exclude other important things we know about
  files.reject! do |f|
    [
      node['fb_bind']['config']['options']['key-directory'],
      new_resource.zones_dir,
      ::File.join(new_resource.zones_dir, 'primary'),
      ::File.join(FB::Bind::CONFIG_DIR, 'rndc.key'),
    ].include?(f)
  end

  return if files.empty?

  Chef::Log.debug("fb_bind: Considering these files for removal: #{files}")

  # if any left, exclude ones owned by packages, and delete the rest
  unowned_files = node.files_unowned_by_pkgmgmt(files)

  Chef::Log.debug(
    "fb_bind: These files are not owned by us or pkgmgmt: #{files}",
  )

  unowned_files.each do |f|
    file f do
      action :delete
    end
  end
end
