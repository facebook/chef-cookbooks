# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

version = node.centos6? ? 1 : 2
grub2_base_dir = '/boot/grub2'
case node['platform']
when 'centos'
  vendor = node.centos6? ? 'redhat' : 'centos'
when 'redhat'
  vendor = 'redhat'
when 'debian'
  grub2_base_dir = '/boot/grub'
  vendor = 'debian'
when 'fedora'
  vendor = 'fedora'
when 'ubuntu'
  grub2_base_dir = '/boot/grub'
  vendor = 'ubuntu'
else
  # Not explicitly failing here because we're in attributes
  vendor = nil
end

fb_grub = {
  '_device_hints' => [],
  '_efi_vendor_dir' => '/notdefined',
  '_grub_base_dir' => '/boot/grub',
  '_grub2_base_dir' => grub2_base_dir,
  '_grub2_copy_path' => nil,
  '_grub2_module_path' => '/notdefined',
  '_rootflags' => nil,
  '_vendor' => vendor,
  'enable_bls' => node.centos? && node.major_platform_version.to_i >= 8,
  'kernel_cmdline_args' => [],
  'kernels' => {},
  'manage_packages' => true,
  'saved_opts' => '',
  'serial' => {
    'unit' => 0,
    'speed' => 57600,
    'word' => 8,
    'parity' => 'no',
    'stop' => 1,
  },
  'tboot' => {
    '_grub_modules' => [
      'relocator.mod',
      'multiboot2.mod',
    ],
    'enable' => false,
    'kernel_extra_args' => [
      'intel_iommu=on',
      'noefi',
    ],
    'logging' => [
      'memory',
    ],
    'tboot_extra_args' => [],
  },
  'terminal' => [
    'console',
  ],
  'timeout' => 5,
  'use_labels' => (version == 2),
  'version' => version,
  'force_both_efi_and_bios' => true,
  'users' => {},
  'require_auth_on_boot' => false,
  'environment' => {},
  'search_enabled' => true,
}

unless vendor.nil?
  # Set the path to the grub config files
  vendor_dir = "/boot/efi/EFI/#{vendor}"
  fb_grub['_efi_vendor_dir'] = vendor_dir
  fb_grub['_grub_config_efi'] = "#{vendor_dir}/grub.conf"
  fb_grub['_grub2_config_efi'] = "#{vendor_dir}/grub.cfg"
  fb_grub['_grub_config_bios'] = "#{fb_grub['_grub_base_dir']}/grub.conf"
  fb_grub['_grub2_config_bios'] = "#{fb_grub['_grub2_base_dir']}/grub.cfg"
  # Have a 'current' variable that will point to the one that should be in use
  if node.efi?
    fb_grub['_grub_config'] = fb_grub['_grub_config_efi']
    fb_grub['_grub2_config'] = fb_grub['_grub2_config_efi']
  else
    fb_grub['_grub_config'] = fb_grub['_grub_config_bios']
    fb_grub['_grub2_config'] = fb_grub['_grub2_config_bios']
  end
end

# Finally set the defaults
default['fb_grub'] = fb_grub
