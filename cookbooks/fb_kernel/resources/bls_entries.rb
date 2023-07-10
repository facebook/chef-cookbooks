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

action :run do
  bls_root = ::File.join(node['fb_kernel']['boot_path'], 'loader', 'entries')
  bls_entries = []

  node['fb_kernel']['kernels'].each do |name, data|
    bls_entry =
      ::File.join(bls_root, "#{node['machine_id']}-#{data['version']}.conf")

    template bls_entry do
      source 'bls-entry.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :kernel => name,
      )
    end

    bls_entries << bls_entry
  end

  Dir.glob("#{bls_root}/*.conf").each do |path|
    unless bls_entries.include?(path)
      file path do
        action :delete
      end
    end
  end
end
