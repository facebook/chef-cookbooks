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

if node['fb_fluentbit']['adopt_package_name_fluent-bit']
  include_recipe 'fb_fluentbit::fluent-bit_default'
else
  Chef::Log.warn("On October 2nd, 2023 fb_fluentbit will adopt the fluent-bit name by default. Please upgrade your
   version to 1.9.9 or newer and set adopt_package_name_fluent-bit to true. On April 15th, 2024 support of td-agen-bit
   name will be dropped")
  include_recipe 'fb_fluentbit::td-agent-bit_default'
end
