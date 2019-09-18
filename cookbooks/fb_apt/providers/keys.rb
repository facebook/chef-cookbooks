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

def whyrun_supported?
  true
end

use_inline_resources

action :run do
  keyring = node['fb_apt']['keyring']
  keyserver = node['fb_apt']['keyserver']
  keys = node['fb_apt']['keys'].to_hash

  if keys && keyring
    installed_keys = []
    if ::File.exist?(keyring)
      cmd = Mixlib::ShellOut.new(
        "LANG=C apt-key --keyring #{keyring} finger --keyid-format long",
      ).run_command
      cmd.error!
      output = cmd.stdout.lines
      Chef::Log.debug("apt-key output: #{output.join("\n")}")
      installed_keys = output.select { |x| x.match(/(\s\w{4}){5}/) }.map do |x|
        x[/(?<keyid>([\w]{4}\s){3}[\w]{4})$/, 'keyid'].delete(' ')
      end
    end
    Chef::Log.debug("Installed keys: #{installed_keys.join(', ')}")

    # Process keys to add
    keys.each do |keyid, key|
      if installed_keys.include?(keyid)
        Chef::Log.debug("Skipping keyid #{keyid} as it's already registered")
      else
        Chef::Log.debug("Processing new keyid #{keyid}")
        if key
          execute "add key for #{keyid} to APT" do
            command "echo '#{key}' | apt-key add -"
          end
        elsif keyserver
          execute "fetch and add key for keyid #{keyid} to APT" do
            command "apt-key adv --keyserver #{keyserver} --recv #{keyid}"
          end
        else
          fail "Cannot fetch key for #{keyid} as keyserver is not defined"
        end
      end
    end

    # Process keys to remove
    installed_keys.each do |keyid|
      if keys.include?(keyid)
        Chef::Log.debug("Not deleting added keyid #{keyid}")
      else
        execute "delete key for #{keyid} from APT" do
          command "apt-key del #{keyid}"
        end
      end
    end
  end
end
