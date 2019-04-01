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

databases = {}

%w{
  aliases
  automount
  ethers
  group
  hosts
  initgroups
  netgroup
  netmasks
  networks
  passwd
  protocols
  publickey
  rpc
  services
  shadow
}.each do |db|
  databases[db] = ['files']
end

# enable the glibc resolver
databases['hosts'] << 'dns'
if node.systemd?
  # mymachines: map UID/GIDs ranges used by containers to useful names
  # systemd: enables resolution of all dynamically allocated service users
  databases['passwd'] += %w{mymachines systemd}
  databases['group'] += %w{mymachines systemd}

  # mymachines: enable resolution of all local containers registered
  #             with machined to their respective IP addresses
  # myhostname: resolve the local hostname to locally configured IP addresses,
  #             as well as "localhost" to 127.0.0.1/::1.
  databases['hosts'] += %w{mymachines myhostname}
end

default['fb_nsswitch'] = {
  'databases' => databases,
}
