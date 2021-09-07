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
  # network scripts uses the fb_modprobe_module resource which depends
  # on the execute[load modules] resource in systemd
  include_recipe 'fb_systemd'
  include_recipe 'fb_modprobe'
  include_recipe 'fb_network_scripts'
  fb_helpers_gated_template '/tmp/testfile' do
    allow_changes node.nw_changes_allowed?
    # purposefully bogus, so we raise UserIDNotFound and catch in spec
    owner 'bogususer123'
    group 'bogususer123'
    mode '0644'
    source 'spec_network.erb'
  end
end
