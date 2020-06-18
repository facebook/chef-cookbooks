# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

resource_name :fb_grubby
provides :fb_grubby
default_action :manage

action_class do
  include FB::Grubby
end

action :manage do
  exclude_args = node['fb_grubby']['exclude_args'].to_set
  # exclude has precedence over include
  include_args = node['fb_grubby']['include_args'].to_set - exclude_args

  node['fb_grubby']['kernels'].each do |kernel_path|
    boot_args = get_boot_args(kernel_path)
    add_args = get_add_args(boot_args, include_args)
    rm_args = get_rm_args(boot_args, exclude_args)

    execute "update GRUB entry for #{kernel_path}" do
      not_if { add_args.empty? && rm_args.empty? }
      command update_grub_cmd(kernel_path, add_args, rm_args)
    end
  end
end
