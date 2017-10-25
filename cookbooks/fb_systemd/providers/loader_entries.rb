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
