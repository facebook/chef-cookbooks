# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

version = node.centos6? ? 1 : 2
vendor =  if node.centos6? then 'redhat'
          elsif node.debian? then 'debian'
          else 'centos'
          end

fb_grub = {
  '_efi_vendor_dir' => '/notdefined',
  '_grub_base_dir' => '/boot/grub',
  '_grub2_base_dir' => '/boot/grub2',
  '_grub2_module_path' => '/notdefined',
  '_vendor' => vendor,
  'terminal' => [
    'console',
  ],
  'serial' => {
    'unit' => 0,
    'speed' => 57600,
    'word' => 8,
    'parity' => 'no',
    'stop' => 1,
  },
  'timeout' => 5,
  'kernel_cmdline_args' => [],
  'kernels' => {},
  'saved_opts' => '',
  'tboot' => {
    'enable' => false,
    'kernel_extra_args' => [
      'intel_iommu=on',
      'noefi',
    ],
    'logging' => [
      'memory',
    ],
  },
  'version' => version,
  'use_labels' => false,
}

if node.efi? && version == 2 && !node.centos6?
  fb_grub['_grub2_linux_statement'] = 'linuxefi'
  fb_grub['_grub2_initrd_statement'] = 'initrdefi'
else
  fb_grub['_grub2_linux_statement'] = 'linux'
  fb_grub['_grub2_initrd_statement'] = 'initrd'
end

# Set the path to the grub config files
if node.efi?
  vendor_dir = "/boot/efi/EFI/#{vendor}"
  fb_grub['_efi_vendor_dir'] = vendor_dir
  fb_grub['_grub_config'] = "#{vendor_dir}/grub.conf"
  fb_grub['_grub2_config'] = "#{vendor_dir}/grub.cfg"
else
  fb_grub['_grub_config'] = "#{fb_grub['_grub_base_dir']}/grub.conf"
  fb_grub['_grub2_config'] = "#{fb_grub['_grub2_base_dir']}/grub.cfg"
end

# If something did put a .before_chef file in place, we will extract
# the root_device from it. If the file does not exist (e.g. on older existing
# systems), we will use our old heuristics and hardcoding in default.rb in
# the recipes folder.
original_grub_config = '/root/grub.before_chef'
if File.exist?(original_grub_config)
  # Grub 2 data looks like this:
  # menuentry 'CentOS (4.0.9-75_fbk14_4148_g37fe86f)' {
  #   set root='(hd0,1)'
  # or
  #   set root='hd0,gpt2'
  #
  #
  # Grub 1 data looks like this:
  # title CentOS (4.0.9-68_fbk12_4058_gd84fdb3)
  #   root (hd0,0)
  #
  # Extracted string will be: hd0,2 regardless
  content = File.read(original_grub_config)
  # This will extract the first root directive from the file that is
  # not a comment.
  # This isn't a very generalizable solution.
  filter_regexp = /^\s*[^#]\s*root[=\s]+['"]?\(?([\w,]+)\)?['"]?/
  original_root_device = content[filter_regexp, 1]
  if original_root_device && !original_root_device.empty?
    # Setting this will make sure we don't
    fb_grub['root_device'] = original_root_device
    Chef::Log.info("Re-using existing root device: #{original_root_device}")
  else
    fail "fb_grub::default Can't parse grub config: #{original_grub_config}"
  end
end

# Finally set the defaults
default['fb_grub'] = fb_grub
