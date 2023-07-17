#
# Cookbook Name:: fb_helpers
# Recipe:: spec
#
# Copyright (c) 2012-present, Facebook, Inc.
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

# This recipe is only for running ChefSpec tests
if defined?(ChefSpec)
  fb_helpers_request_nw_changes 'manage' do
    action :nothing
    delayed_action :cleanup_signal_files_when_no_change_required
  end

  service 'critical_service' do
    action :nothing
  end

  fb_helpers_gated_template '/tmp/testfile' do
    allow_changes node.nw_changes_allowed?
    owner 'root'
    group 'root'
    mode '0644'
    source 'spec_network.erb'
    notifies :restart, 'service[critical_service]', :immediately
  end
end
