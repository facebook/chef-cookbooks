#
# Cookbook:: fb_consul
# Recipe:: server_fw
#
# Copyright (c) 2020-present, Vicarious, Inc.
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

node.default['fb_iptables']['filter']['INPUT']['rules']['consul']['rules'] +=
  [
    # Used to handle incoming connections by Consul agents
    '-p tcp --dport 8300 -j ACCEPT',
    # Gossip protocol between Consul servers
    '-p tcp --dport 8302 -j ACCEPT',
    '-p udp --dport 8302 -j ACCEPT',
    # HTTP ui
    '-p tcp --dport 8500 -j ACCEPT',
  ]
