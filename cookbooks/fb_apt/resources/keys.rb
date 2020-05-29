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
  keyserver = node['fb_apt']['keyserver']
  desired_keys = node['fb_apt']['keys'].to_hash

  if desired_keys
    installed_keys = FB::Apt.get_installed_keyids(node)
    Chef::Log.debug(
      "fb_apt[keys]: Installed keys: #{installed_keys.join(', ')}",
    )

    legit_keyrings = FB::Apt._get_owned_keyring_files(node)
    Dir.glob('/etc/apt/trusted.gpg.d/*').each do |keyring|
      next if legit_keyrings.include?(keyring)

      if node['fb_apt']['preserve_unknown_keyrings']
        Chef::Log.warn(
          "fb_apt[keys]: Unknown keyring #{keyring} being preserved!",
        )
      else
        file keyring do
          action :delete
        end
      end
    end

    # Process keys to add
    desired_keys.each do |keyid, key|
      if installed_keys.include?(keyid)
        Chef::Log.debug(
          "fb_apt[keys]: Skipping keyid #{keyid} as it's already registered",
        )
      else
        Chef::Log.debug("fb_apt[keys]: Processing new keyid #{keyid}")
        if key
          execute "add key for #{keyid} to APT" do
            command "echo '#{key}' | apt-key add -"
          end
        elsif keyserver
          execute "fetch and add key for keyid #{keyid} to APT" do
            command "apt-key adv --keyserver #{keyserver} --recv #{keyid}"
            # with the DDOS against PGP Keyservers, we need to try
            # several times
            retries 2
          end
        else
          fail "Cannot fetch key for #{keyid} as keyserver is not defined"
        end
      end
    end

    # Process keys to remove
    installed_keys.each do |keyid|
      if desired_keys.keys.include?(keyid)
        Chef::Log.debug("fb_apt[keys]: Not deleting added keyid #{keyid}")
      else
        execute "delete key for #{keyid} from APT" do
          command "apt-key del #{keyid}"
        end
      end
    end
  end
end
