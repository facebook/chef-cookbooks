# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

use_inline_resources

def whyrun_supported?
  true
end

action :install do
  packages = []
  case node['fb_grub']['version']
  when 1
    if node.debian?
      packages << 'grub-legacy'
    else
      packages << 'grub'
    end
  when 2
    if node.debian?
      packages += %w{grub-efi}
      unless node.aarch64?
        packages << 'grub-pc'
      end
    else
      packages += %w{grub2-efi grub2-efi-modules grub2-tools}
      unless node.aarch64?
        packages << 'grub2'
      end
    end
  else
    fail "Unsupported grub version: #{node['fb_grub']['version']}"
  end

  if node['fb_grub']['tboot']['enable']
    packages << 'tboot'
  end

  package 'grub packages' do
    package_name packages
    action :upgrade
  end
end
