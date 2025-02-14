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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
action :run do
  desired_keyids = node['fb_apt']['keys']
  desired_keys = node['fb_apt']['keymap']

  # if the user hasn't specified any keys of any time, don't manage
  # keys in anyway
  unless desired_keys || desired_keyids
    return
  end

  directory FB::Apt::PEM_D do
    owner node.root_user
    group node.root_group
    mode '0755'
  end

  # Remove unwanted keyrings
  legit_keyrings = FB::Apt._get_owned_keyring_files(node) +
    desired_keys.keys.map { |x| FB::Apt.keyring_path_from_name(x) }
  Dir.glob("#{FB::Apt::TRUSTED_D}/*").each do |keyring|
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
  Dir.glob("#{FB::Apt::PEM_D}/*").each do |pem|
    basename = ::File.basename(pem, '.asc')
    next if desired_keys[basename]
    file pem do
      action :delete
    end
  end

  # Generate wanted keyrings from PEMs passed in
  desired_keys.each do |name, key|
    src = FB::Apt.pem_path_from_name(name)
    dst = FB::Apt.keyring_path_from_name(name)
    if key.start_with?('http')
      remote_file dst do
        source key
        owner node.root_user
        group node.root_group
        mode '0644'
      end
      next
    end

    file src do
      owner node.root_user
      group node.root_group
      mode '0644'
      content "# This file is staging for Chef's fb_apt\n#{key}"
      # delete the file or gpg will prompt to overwrite it
      notifies :delete, "file[#{dst}]", :immediately
      notifies :run, "execute[generate #{name} keyring]", :immediately
    end

    file dst do
      action :nothing
    end

    execute "generate #{name} keyring" do
      command "gpg --dearmor -o #{dst} #{src}"
      action :nothing
    end
  end

  # Begin support for LEGACY stuff
  #
  # This stuff uses apt-key (deprecated) to add/remove/list stuff from
  # /etc/apt/trusted.gpg. It even attempts to download keys from the internet,
  # which is also deprecated.
  unless desired_keyids.empty?
    Chef::Log.warn(
      'fb_apt: `node["fb_apt"]["keys"]` is deprecated! Please migrate to' +
      ' `node["fb_apt"]["keymap"]',
    )
    installed_keys = FB::Apt.get_legacy_keyids

    # Walk legacy keys and install them. This will install into
    # the deprecated /etc/apt/trusted.gpg and is not gauranteed to work.
    desired_keyids.each do |keyid, key|
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

    # Then walk everything installed and remove what we don't expect
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
