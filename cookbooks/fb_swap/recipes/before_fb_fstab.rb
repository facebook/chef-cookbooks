#
# Cookbook Name:: fb_swap
# Recipe:: before_fb_fstab
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
require 'shellwords'

# Newly provisioned hosts end up with a swap device in /etc/fstab which
# is referenced by UUID (or label, or path). We use data from ohai's
# filesystem2 plugin (which is backed by the state of the machine, not what
# is in /etc/fstab). We want to create/manage our own units with predictable
# names
#
node.default['fb_fstab']['exclude_base_swap'] = true

whyrun_safe_ruby_block 'Validate and calculate swap sizes' do
  block do
    FB::FbSwap._validate(node)
  end
end

['device', 'file'].each do |type|
  next if type == 'device' && FB::FbSwap._device(node).nil?
  manage_unit = "manage-swap-#{type}.service"

  whyrun_safe_ruby_block "Add #{type} swap to fstab" do
    only_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    block do
      # ask fb_fstab to create the unit
      node.default['fb_fstab']['mounts']["swap_#{type}"] = {
        'mount_point' => 'swap',
        'device' => FB::FbSwap._path(node, type),
        'type' => 'swap',
        # prioritize swap file in case that swap partition is on a spinning disk
        'opts' => type == 'file' ? 'pri=10' : 'pri=5',
      }
    end
  end

  template "/etc/systemd/system/#{manage_unit}" do
    source "#{manage_unit}.erb"
    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
    notifies :restart, "service[#{manage_unit}]"
  end

  # Note: FC022 is masked because the unit name is derived from the type
  # variable in the loop
  service manage_unit do # ~FC022
    # we can get restarted, but we don't need to enable/start this explicitly
    # due to the use of BindsTo on the swap unit
    action :nothing
    # make the resource disappear if the measured size is the same as the
    # expected size. This fixes the bootstrap case where manage_unit
    # is first created and swap is already enabled and correct.
    not_if do
      node['fb_swap']['_calculated']["#{type}_size_bytes"] ==
        node['fb_swap']['_calculated']["#{type}_current_size_bytes"]
    end
    # Restarting this unit itself is fairly fast but it's tied to the swap unit
    # by a PartOf relationship. The systemd provider for the service resource
    # will block because systemctl will block until the service is started.
    #
    # The systemd provider for the service resource has no way to pass
    # --no-block to systemctl, so we have to call it ourselves.
    restart_command '/usr/bin/systemctl --system --no-block restart ' +
      Shellwords.escape(manage_unit)
  end

  # Override the fb_fstab -> fstab-generator unit with some extra deps
  # Note that swap units are more limited in what systemd options they
  # take from the options column.
  fb_systemd_override "#{type} swap override" do
    only_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    override_name 'manage'
    unit_name lazy { FB::FbSwap._swap_unit(node, type) }
    content(
      lazy do
        {
          'Unit' => {
            'BindsTo' => manage_unit,
            'After' => manage_unit,
            'PartOf' => manage_unit,
          },
          # Stopping swap is pathologically slow on Linux today. The general
          # default for stopping units in systemd is 90s. Here we'll use
          # 100s per GiB as a heuristic on top of the default.
          'Swap' => {
            'TimeoutSec' => 90 + 100 *
            (node['fb_swap']['_calculated']["#{type}_size_bytes"] / 2**30),
          },
        }
      end,
    )
  end

  fb_systemd_override "remove #{type} swap override" do
    not_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    override_name 'manage'
    unit_name lazy { FB::FbSwap._swap_unit(node, type) }
    action :delete
  end
end

template '/usr/local/libexec/manage-swap-file' do
  source 'manage-swap-file.sh.erb'
  owner 'root'
  group 'root'
  # read/execute for root, read only for everyone else.
  mode '0544'
  notifies :restart, 'service[manage-swap-file.service]'
end
