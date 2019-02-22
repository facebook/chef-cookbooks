#
# Cookbook Name:: fb_swap
# Recipe:: before_fb_fstab
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
      }
    end
  end

  # T40484873 always unmask swap units
  # Remove after 2019-03-01
  service "unmask #{type} swap" do
    service_name lazy { FB::FbSwap._swap_unit(node, type) }
    action [:unmask]
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
  file "remove #{type} manage.conf" do
    not_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    path lazy { FB::FbSwap._manage_conf(node, type) }
    action :delete
  end

  directory "remove #{type} override_dir" do
    not_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    path lazy { FB::FbSwap._override_dir(node, type) }
    action :delete
  end

  directory "create #{type} override_dir" do
    only_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    path lazy { FB::FbSwap._override_dir(node, type) }
    owner 'root'
    group 'root'
    mode '0755'
  end

  # Note: FB031 is masked because the path is worked out at runtime.
  template "template #{type} manage.conf" do # ~FB031
    only_if { node['fb_swap']['_calculated']["#{type}_size_bytes"].positive? }
    path lazy { FB::FbSwap._manage_conf(node, type) }
    source 'manage-override.conf.erb'
    variables(:type => type)
    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, 'fb_systemd_reload[system instance]', :immediately
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
