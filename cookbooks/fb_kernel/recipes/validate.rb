#
# Cookbook Name:: fb_kernel
# Recipe:: validate
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

whyrun_safe_ruby_block 'validate kernels' do
  not_if { node['fb_kernel']['kernels'].empty? }
  block do
    kernels = node['fb_kernel']['kernels'].to_hash
    kernels.each do |name, data|
      unless data['title']
        data['title'] = "CentOS (#{name})"
      end
      unless data['version']
        data['version'] = name
      end
      unless data['linux']
        data['linux'] = "/vmlinuz-#{data['version']}"
      end
      vmlinuz_path = File.join(node['fb_kernel']['boot_path'], data['linux'])
      unless File.exist?(vmlinuz_path)
        fail "fb_kernel: #{vmlinuz_path} does not exist"
      end
      unless data['id']
        ctime = File.ctime(vmlinuz_path).strftime('%Y%m%d%H%M%S')
        data['id'] = "centos-#{ctime}-#{data['version']}"
      end
      unless data['initrd']
        data['initrd'] = "/initramfs-#{data['version']}.img"
      end
      initrd_path = File.join(node['fb_kernel']['boot_path'], data['initrd'])
      unless File.exist?(initrd_path)
        fail "fb_kernel: #{initrd_path} does not exist"
      end
      unless data['options']
        data['options'] = '$kernelopts'
      end
    end
    node.default['fb_kernel']['kernels'] = kernels
  end
end
