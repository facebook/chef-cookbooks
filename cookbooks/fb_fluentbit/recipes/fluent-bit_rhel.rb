#
# Copyright (c) 2020-present, Facebook, Inc.
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

package 'Install FluentBit' do
  only_if { node['fb_fluentbit']['manage_packages'] }
  package_name 'fluent-bit'
  action :upgrade
  notifies :restart, 'service[fluent-bit]'
end

package 'Install fluentbit external plugins' do
  only_if { node['fb_fluentbit']['plugin_manage_packages'] }
  package_name lazy {
    FB::Fluentbit.external_plugins_from_node(node).map(&:package).sort.uniq
  }
  action :upgrade
  notifies :restart, 'service[fluent-bit]'
end
