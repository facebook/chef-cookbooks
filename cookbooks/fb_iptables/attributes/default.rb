# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
