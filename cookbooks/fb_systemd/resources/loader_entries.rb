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

action :run do
  esp_path = node['fb_systemd']['boot']['path']
  entries = node['fb_systemd']['boot']['entries'].to_hash

  Dir.glob("#{esp_path}/loader/entries/fb_systemd_*.conf").each do |path|
    entry = /^fb_systemd_(\w+)\.conf$/.match(::File.basename(path))
    if entry && !entries.include?(entry[1]) # ~FC023
      file path do
        action :delete
      end
    end
  end

  entries.each_key do |entry|
    template "#{esp_path}/loader/entries/fb_systemd_#{entry}.conf" do
      source 'loader-entry.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        :entry => entry,
      )
    end
  end
end
