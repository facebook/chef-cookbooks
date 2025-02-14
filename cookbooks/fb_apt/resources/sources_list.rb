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
  base_sources = FB::Apt.base_sources(node)
  # update repos list and ensure base repos come first
  node.default['fb_apt']['sources'] = base_sources.merge(
    node['fb_apt']['sources'],
  )

  unless node['fb_apt']['repos'].empty?
    Chef::Log.warn(
      'fb_apt: `node["fb_apt"]["repos"]` is deprecated. Please migrate to' +
      ' `node["fb_apt"]["sources"]`.',
    )
  end

  template '/etc/apt/sources.list' do
    source 'sources.list.erb'
    owner node.root_user
    group node.root_group
    mode '0644'
  end
end
