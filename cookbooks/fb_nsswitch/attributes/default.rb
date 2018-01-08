# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
