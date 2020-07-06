#
# Cookbook Name:: fb_limits
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

template '/etc/security/limits.conf' do
  source 'limits.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# We want to manage all limits config via /etc/security/limits.conf, so clean
# out limits.d/*.conf. Instead of deleting the directory, just overwrite the
# files with a comment indicating they were disabled by Chef. This is important
# so that upgrading or reinstalling an RPM that ships one such config file will
# not end up creating the file back again.
Dir.glob '/etc/security/limits.d/*.conf' do |i|
  file "overwrite #{i} in /etc/security/limits.d" do
    path i
    content "# Disabled by Chef\n"
    owner 'root'
    group 'root'
    mode '0644'
  end
end
