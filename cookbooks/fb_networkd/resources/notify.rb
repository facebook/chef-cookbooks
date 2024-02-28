# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2023-present, Facebook, Inc.
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
default_action :trigger

action :trigger do
  if Chef::VERSION.to_i >= 16
    notify_group 'notify resources after networkd change' do # rubocop:disable Chef/Meta/Chef16
      node['fb_networkd']['notify_resources'].each do |my_r, my_a|
        notifies my_a, my_r
      end
      action :run
    end
  else
    log 'notify resources after networkd change' do
      node['fb_networkd']['notify_resources'].each do |my_r, my_a|
        notifies my_a, my_r
      end
      action :write
    end
  end
end

action :stop do
  if Chef::VERSION.to_i >= 16
    notify_group 'stop resources before networkd change' do # rubocop:disable Chef/Meta/Chef16
      node['fb_networkd']['stop_before'].each do |r|
        notifies :stop, r, :immediately
      end
      action :run
    end
  else
    log 'stop resources before networkd change' do
      node['fb_networkd']['stop_before'].each do |r|
        notifies :stop, r, :immediately
      end
      action :write
    end
  end
end

action :start do
  if Chef::VERSION.to_i >= 16
    notify_group 'start resources after networkd change' do # rubocop:disable Chef/Meta/Chef16
      node['fb_networkd']['stop_before'].each do |r|
        notifies :start, r
      end
      action :run
    end
  else
    log 'start resources after networkd change' do
      node['fb_networkd']['stop_before'].each do |r|
        notifies :start, r
      end
      action :write
    end
  end
end
