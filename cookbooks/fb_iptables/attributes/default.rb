# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

DEFAULT_POLICY = 'ACCEPT'.freeze

iptables = {
  'enable' => false,
  'manage_packages' => true,
  'sysconfig' => {
    'modules' => '',
    'modules_unload' => 'yes',
    'save_on_stop' => 'no',
    'save_on_restart' => 'no',
    'save_counter' => 'no',
    'status_numeric' => 'yes',
    'status_verbose' => 'no',
    'status_linenumbers' => 'yes',
  },
  'dynamic_chains' => {
    'filter' => {},
    'mangle' => {},
    'raw' => {},
  },
}

FB::Iptables::TABLES_AND_CHAINS.each do |table, chains|
  iptables[table] = {}
  chains.each do |chain|
    iptables[table][chain] = {
      'policy' => DEFAULT_POLICY,
      'rules' => {},
    }
  end
end

default['fb_iptables'] = iptables
