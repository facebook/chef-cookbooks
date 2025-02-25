#
# Cookbook:: fb_letsencrypt
# Recipe:: default
#
# Copyright:: 2025-present, Meta Platforms, Inc.
# Copyright:: 2025-present, Phil Dibowitz
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

package 'certbot packages' do
  only_if { node['fb_letsencrypt']['manage_packages'] }
  package_name lazy {
    (
      %w{certbot} + node['fb_letsencrypt']['certbot_plugins'].map do |plugin|
        "python3-certbot-#{plugin}"
      end
    ).uniq
  }
  action :upgrade
end

service 'conditionally enable certbot.timer' do
  only_if { node['fb_letsencrypt']['enable_package_timer'] }
  service_name 'certbot.timer'
  action [:enable, :start]
end

service 'conditionally disable certbot.timer' do
  not_if { node['fb_letsencrypt']['enable_package_timer'] }
  service_name 'certbot.timer'
  action [:stop, :disable]
end
