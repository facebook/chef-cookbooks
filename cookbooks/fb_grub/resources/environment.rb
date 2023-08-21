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
action :manage do
  to_unset = []
  to_set = []

  node['fb_grub']['environment'].each do |key, val|
    current_val = node['grub2']['environment'][key]
    if val.nil? && !current_val.nil?
      to_unset << key
    elsif val != current_val
      to_set << key
    end
  end

  if to_unset
    execute 'unset grub2 environment keys' do
      command "grub2-editenv - unset '#{to_unset.join(' ')}'"
    end
  end

  if to_set
    toset_str = ''
    to_set.each do |key|
      toset_str += "'#{key}'='#{node['fb_grub']['environment'][key]}'"
    end
    execute 'set grub2 environment keys' do
      command "grub2-editenv - set #{toset_str}"
    end
  end
end
