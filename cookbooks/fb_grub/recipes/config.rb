#
# Cookbook Name:: fb_grub
# Recipe:: config
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

grub_base_dir = node['fb_grub']['_grub_base_dir']
grub2_base_dir = node['fb_grub']['_grub2_base_dir']

directory 'efi_vendor_dir' do # rubocop:disable Chef/Meta/RequireOwnerGroupMode # ~FB024 mode is controlled by mount options
  only_if { node.efi? }
  path lazy { node['fb_grub']['_efi_vendor_dir'] }
  owner 'root'
  group 'root'
end

# GRUB 1
directory grub_base_dir do
  only_if { node['fb_grub']['version'] == 1 }
  owner 'root'
  group 'root'
  mode '0755'
end

template 'grub_config' do
  only_if do
    node['platform_family'] == 'rhel' && node['fb_grub']['kernels'] &&
      node['fb_grub']['version'] == 1
  end
  path lazy { node['fb_grub']['_grub_config'] }
  source 'grub.conf.erb'
  owner 'root'
  group 'root'
  mode node.efi? ? '0700' : '0644'
end

template 'Additional grub.conf' do
  # We need the same config in /boot/efi/... AND /boot/grub if it's EFI,
  # because grub sometimes gets installed on hd0,1 which is /boot
  only_if do
    node.efi? && node['platform_family'] == 'rhel' &&
      node['fb_grub']['kernels'] && node['fb_grub']['version'] == 1
  end
  path '/boot/grub/grub.conf'
  source 'grub.conf.erb'
  owner 'root'
  group 'root'
  mode node.efi? ? '0700' : '0644'
end

# GRUB 2
directory grub2_base_dir do
  only_if { node['fb_grub']['version'] == 2 }
  owner 'root'
  group 'root'
  mode '0755'
end

%w{bios efi}.each do |type|
  # For grub 2, we MAY be able to write both efi and bios config files
  # if the user wants us to
  if type == 'efi'
    our_type = node.efi?
  else
    our_type = !node.efi?
  end
  # efi command suffixing is a special case in grub2 that only applies
  # to x86_64.
  efi_command = type == 'efi' && node.x64?

  template "grub2_config_#{type}" do
    only_if do
      (node['fb_grub']['kernels'] && node['fb_grub']['version'] == 2) &&
      (our_type || node['fb_grub']['force_both_efi_and_bios'])
    end
    path lazy { node['fb_grub']["_grub2_config_#{type}"] }
    source 'grub2.cfg.erb'
    owner 'root'
    group 'root'
    # No "mode" for EFI since mode is determined by mount options,
    # not files
    if type == 'bios'
      mode lazy {
        if node['fb_grub']['users'].empty?
          '0644'
        else
          '0600'
        end
      }
    end
    variables(
      {
        'linux_statement' => efi_command ? 'linuxefi' : 'linux',
        'initrd_statement' => efi_command ? 'initrdefi' : 'initrd',
      },
    )
  end
end

# grub2 cannot read / if it's compressed with zstd, so hack around it
node['fb_grub']['tboot']['_grub_modules'].each do |mod_file|
  remote_file "Copy #{mod_file} file for grub" do
    only_if do
      node['fb_grub']['tboot']['enable'] &&
      !node['fb_grub']['_grub2_copy_path'].nil?
    end
    path "/boot/#{mod_file}"
    source lazy { "file://#{node['fb_grub']['_grub2_copy_path']}/#{mod_file}" }
    owner 'root'
    group 'root'
    mode '0644'
  end
end

# cleanup configs for the grub major version that we're not using
['_grub_config_bios', '_grub_config_efi'].each do |tpl_name|
  file "cleanup #{tpl_name}" do
    not_if { node['fb_grub']['version'] == 1 }
    path lazy { node['fb_grub'][tpl_name] }
    action :delete
  end
end

if grub_base_dir != grub2_base_dir
  directory "cleanup #{grub_base_dir}" do
    not_if { node['fb_grub']['version'] == 1 }
    path grub_base_dir
    action :delete
    recursive true
  end
end

['_grub2_config_bios', '_grub2_config_efi'].each do |tpl_name|
  file "cleanup grub2_config #{tpl_name}" do
    not_if { node['fb_grub']['version'] == 2 }
    path lazy { node['fb_grub'][tpl_name] }
    action :delete
  end
end

directory "cleanup #{grub2_base_dir}" do
  not_if { node['fb_grub']['version'] == 2 }
  path grub2_base_dir
  action :delete
  recursive true
end

link '/etc/grub.conf' do
  to lazy {
    if node['fb_grub']['version'] == 2
      node['fb_grub']['_grub2_config']
    else
      node['fb_grub']['_grub_config']
    end
  }
end

fb_grub_environment 'manage GRUB2 environment' do
  only_if do
    node['fb_grub']['version'] == 2 &&
      !node['fb_grub']['environment'].empty? &&
      node['grub2']
  end
end
