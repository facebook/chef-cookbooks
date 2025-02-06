# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2020-present, Facebook, Inc.
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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
action :run do
  installed_versions = []
  node['packages']['kernel']['versions'].each do |v|
    installed_versions << "#{v['version']}-#{v['release']}"
  end

  wanted_versions = []
  node['fb_kernel']['kernels'].each do |name, data|
    if data['version']
      kernel_version = data['version']
    else
      kernel_version = name
    end
    wanted_versions << kernel_version
  end

  # we remove before installing to make space in the /boot partition
  installed_versions.each do |v|
    # never remove the currently booted kernel
    next if v == node['kernel']['release']
    unless wanted_versions.include?(v)
      if v.include?('kdump')
        kernel_packages = ['kernel-kdump']
      else
        kernel_packages = ['kernel']
      end
      # always remove kernel-devel too if we're removing a kernel
      kernel_packages << 'kernel-devel'
      kernel_packages.each do |pkg|
        package pkg do
          if node['fb_kernel']['remove_options']
            options node['fb_kernel']['remove_options']
          end
          version v
          action :remove
        end
      end
    end
  end

  # also remove unowned kernel arifacts that aren't accounted for
  %w{
    config
    initramfs
    vmlinuz
    System.map
  }.each do |prefix|
    Dir.glob(::File.join(boot_path, "#{prefix}-[0-9]*")).each do |f|
      v = f.match("#{prefix}-(?:kdump-)?(.*)")[1]
      # never remove the currently booted kernel
      next if v == node['kernel']['release']
      unless wanted_versions.include?(v)
        file f do
          action :delete
        end
      end
    end
  end

  wanted_versions.each do |v|
    unless installed_versions.include?(v)
      if v.include?('kdump')
        kernel_packages = ['kernel-kdump']
      else
        kernel_packages = ['kernel']
      end
      if node['fb_kernel']['want_devel']
        kernel_packages << 'kernel-devel'
      else
        package 'kernel-devel' do
          if node['fb_kernel']['remove_options']
            options node['fb_kernel']['remove_options']
          end
          version v
          action :remove
        end
      end
      kernel_packages.each do |pkg|
        package pkg do
          if node['fb_kernel']['install_options']
            options node['fb_kernel']['install_options']
          end
          version v
          action :install
        end
      end
    end
  end
end
