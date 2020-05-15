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
  settings = node['fb_motd']['update_motd']
  Dir.glob('/etc/update-motd.d/*').each do |motd|
    fname = ::File.basename(motd)
    allow = false
    if settings['enabled']
      if settings['whitelist'].empty?
        # if we're NOT using a whitelist, then the default is allow
        allow = true
      else
        # if we *are* using a whitelist, then we only allow if it's in the
        # list
        allow = settings['whitelist'].include?(fname)
      end
      if !settings['blacklist'].empty? && settings['blacklist'].include?(fname)
        # if we are using a blacklist, and if it's in the blacklist
        # then no matter what, remove it
        allow = false
      end
    else
      allow = false
    end

    file motd do
      owner 'root'
      group 'root'
      mode allow ? '0755' : '0644'
    end
  end
end
