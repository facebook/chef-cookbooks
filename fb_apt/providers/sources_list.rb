# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

def whyrun_supported?
  true
end

use_inline_resources

action :run do
  repos = []
  mirror = node['fb_apt']['mirror']
  distro = node['lsb']['codename']

  # only add base repos if mirror is set and codename is available
  if mirror && distro
    components = %w{main}
    if node.ubuntu?
      components << 'universe'
    end

    if node['fb_apt']['want_non_free']
      if node.debian?
        components += %w{contrib non-free}
      elsif node.ubuntu?
        components += %w{restricted multiverse}
      else
        fail "Don't know how to setup non-free for #{node['platform']}"
      end
    end

    components_entry = components.join(' ')
    base_repos = [
      # Main repo
      "#{mirror} #{distro} #{components_entry}",
    ]

    # Security updates
    if node.debian? && distro != 'sid'
      base_repos <<
        "http://security.debian.org/ #{distro}/updates #{components_entry}"
    elsif node.ubuntu?
      base_repos <<
        "http://security.ubuntu.com/ #{distro}-security #{components_entry}"
    end

    # Stable updates
    base_repos << "#{mirror} #{distro}-updates #{components_entry}"

    if node['fb_apt']['want_backports']
      base_repos << "#{mirror} #{distro}-backports #{components_entry}"
    end

    base_repos.each do |repo|
      repos << "deb #{repo}"
      if node['fb_apt']['want_source']
        repos << "deb-src #{repo}"
      end
    end
  end

  # add custom repos
  repos += node['fb_apt']['repos']

  template '/etc/apt/sources.list' do
    source 'sources.list.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(:repos => repos)
  end
end
