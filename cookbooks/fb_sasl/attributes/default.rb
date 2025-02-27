#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

# because the attributes file is consumed in the node context,
# 'debian?' will be fb_helper's node.debian? which is not what we
# want, so specify full path
if fedora_derived?
  sysconfig = {
    'socketdir' => '/run/saslauthd',
    'mech' => 'pam',
    'flags' => '',
  }
elsif ChefUtils.debian?
  sysconfig = {
    'desc' => 'SASL Authentication Daemon',
    'name' => 'saslauthd',
    'mechanisms' => 'pam',
    'mech_options' => '',
    'threads' => 5,
    'options' => '-c -m /var/run/saslauthd',
  }
else
  fail "fb_sasl: Unknown platform_family: #{node['platform_family']}"
end

default['fb_sasl'] = {
  'manage_packages' => true,
  'modules' => [],
  'enable_saslauthd' => false,
  'sysconfig' => sysconfig,
}
