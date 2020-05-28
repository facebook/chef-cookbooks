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
  mirror = node['fb_apt']['mirror']
  security_mirror = node['fb_apt']['security_mirror']
  # By default, we want our current distro to assemble to repo URLs.
  # However, for when people want to upgrade across distros, we let
  # them specify a distro to upgrade to.
  distro = node['fb_apt']['distro'] || node['lsb']['codename']

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
        "#{security_mirror} #{distro}/updates #{components_entry}"
    elsif node.ubuntu?
      base_repos <<
        "#{security_mirror} #{distro}-security " +
        components_entry
    end

    # Debian Sid doesn't have updates or backports
    unless node.debian? && distro == 'sid'
      # Stable updates
      base_repos << "#{mirror} #{distro}-updates #{components_entry}"

      if node['fb_apt']['want_backports']
        base_repos << "#{mirror} #{distro}-backports #{components_entry}"
      end
    end

    repos = []
    base_repos.each do |repo|
      repos << "deb #{repo}"
      if node['fb_apt']['want_source']
        repos << "deb-src #{repo}"
      end
    end

    # update repos list and ensure base repos come first
    node.default['fb_apt']['repos'] = repos + node['fb_apt']['repos']
  end

  template '/etc/apt/sources.list' do
    source 'sources.list.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
end
