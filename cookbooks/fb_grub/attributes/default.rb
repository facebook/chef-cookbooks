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
if node.centos6? || node.redhat?
  vendor = 'redhat'
elsif node.debian?
  grub2_base_dir = '/boot/grub'
  vendor = 'debian'
elsif node.ubuntu?
  vendor = 'ubuntu'
  grub2_base_dir = '/boot/grub'
else
  vendor = 'centos'
end

fb_grub = {
  '_device_hints' => [],
  '_efi_vendor_dir' => '/notdefined',
  '_grub_base_dir' => '/boot/grub',
  '_grub2_base_dir' => grub2_base_dir,
  '_grub2_copy_path' => nil,
  '_grub2_module_path' => '/notdefined',
  '_vendor' => vendor,
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
  'use_labels' => false,
  'version' => version,
  'force_both_efi_and_bios' => true,
}

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

# This file is a temporary measure until we are in a glorious 'all grub 2'
# environment. The grub.use_labels file helps us with NOT rolling
# the new default out to existing machines
if version == 2 && File.exist?('/root/grub.use_labels')
  fb_grub['use_labels'] = true
else
  # We are apparently not using labels, so we have to do some detective work.
  # If something did put a .before_chef file in place, we will extract
  # the root_device from it. If the file does not exist (e.g. on older existing
  # systems), we will use our old heuristics and hardcoding in default.rb in
  # the recipes folder.
  original_grub_config = '/root/grub.before_chef'
  if File.exist?(original_grub_config)
    content = File.read(original_grub_config)
    original_root_device = FB::Grub.extract_root_device(content)
    original_device_hints = FB::Grub.extract_device_hints(content)
    if original_root_device
      # Setting this will make sure we don't
      fb_grub['root_device'] = original_root_device
      Chef::Log.debug("Re-using existing root device: #{original_root_device}")
      fb_grub['_device_hints'] = original_device_hints
      Chef::Log.debug("Found #{original_device_hints.size} grub device hints.")
    else
      Chef::Log.warn("fb_grub::default Can't parse grub config: " +
                     original_grub_config.to_s)
    end
  end
end

# Finally set the defaults
default['fb_grub'] = fb_grub
