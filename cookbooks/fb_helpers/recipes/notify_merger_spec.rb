# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Facebook, Inc.
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

# This recipe is only for running ChefSpec tests
if defined?(ChefSpec)
  nm_resource = 'fb_notify_merger[ruby block 3]'

  ruby_block 'some ruby block 1' do
    block {}
    notifies :update, nm_resource, :immediately
  end

  ruby_block 'some ruby block 2' do
    block {}
    notifies :update, nm_resource, :immediately
  end

  fb_notify_merger 'ruby block 3' do
    notifies :run, 'ruby_block[some ruby block 3]', :immediately
  end

  ruby_block 'some ruby block 3' do
    block {}
    action :nothing
  end

  ruby_block 'late ruby block' do
    only_if { node['guard_update'] }
    block {}
    notifies :update, nm_resource, :immediately
  end

  ruby_block 'later ruby block' do
    only_if { node['guard_merge'] }
    block {}
    notifies :merge, nm_resource, :immediately
  end
end
