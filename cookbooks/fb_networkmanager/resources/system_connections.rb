#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
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

action_class do
  include FB::Networkmanager::Resource
end

action :manage do
  node['fb_networkmanager']['system_connections'].each do |name, userconfig|
    config = userconfig.to_hash.dup
    files = determine_files(name, config)

    current, new_config = generate_config_hashes(files['from'], config)

    template files['config'] do
      # we don't rely just on the idempotency of the template because
      # there's no guarantee that NM writes stuff in the same order we
      # would, so we compare the useful contents
      only_if { new_config != current }
      owner 'root'
      group 'root'
      mode '0600'
      helper(:data) { new_config }
      source 'nm.conf.erb'
    end

    if files['migrate']
      file files['migrate'] do
        action :delete
      end
    end
  end

  allowed = allowed_connections(node)

  Dir.glob("#{conf_path('')}*").each do |f|
    name = ::File.basename(f)
    next if allowed.include?(name)

    file f do
      action :delete
    end
  end
end
