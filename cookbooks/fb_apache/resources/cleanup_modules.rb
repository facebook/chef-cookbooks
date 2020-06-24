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

property :mod_dir, String

action :manage do
  allowed = [
    "#{new_resource.mod_dir}/00-mpm.conf",
    "#{new_resource.mod_dir}/fb_modules.conf",
  ]
  Dir.glob("#{new_resource.mod_dir}/*").each do |f|
    next if allowed.include?(f)
    if ::File.symlink?(f)
      link f do
        action :delete
      end
    else
      file f do
        action :delete
      end
    end
  end
end
