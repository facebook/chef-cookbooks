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
      if node.efi?
        packages << 'grub-efi'
        unless node.aarch64?
          packages << 'grub-efi-amd64'
        end
      else
        packages << 'grub-pc'
      end
    elsif node.ubuntu?
      packages += %w{
        grub2
        grub2-common
        grub-pc
        grub-pc-bin
      }
    elsif node.efi?
      packages += %w{grub2-efi grub2-efi-modules grub2-tools}
    else
      packages << 'grub2'
    end
  else
    fail "fb_grub: unsupported grub version: #{node['fb_grub']['version']}"
  end

  if node['fb_grub']['tboot']['enable']
    packages << 'tboot'
  end

  package 'grub packages' do
    package_name packages
    action :upgrade
  end
end
