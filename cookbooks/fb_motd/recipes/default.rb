#
# Cookbook Name:: fb_motd
# Recipe:: default
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

template '/etc/motd' do
  group 'root'
  mode '0644'
  owner 'root'
  source 'motd.erb'
end

# Ubuntu's motd is heavily modified and consists of a few basic parts:
# * standard /etc/motd (though it's often a symlink to /run/motd.dynamic,
#   if it's not, it'll be the last part of the motd shown)
# * /run/motd.dynamic which is a cache of the output of running everything
#   in /etc/update-motd.d using `run-parts`. Various packages drop things
#   off in here and the accepted way to disable them is to make them
#   non-executable
# * motd-news - a live-go-get-something-from-the-internet-and-display-
#   it-at-login. This can be disabled in /etc/default/motd-news
if node.ubuntu?
  template '/etc/default/motd-news' do
    owner 'root'
    group 'root'
    mode '0644'
  end

  fb_motd_update_motd 'doit'
end
