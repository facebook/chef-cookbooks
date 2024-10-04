#
# Copyright (c) 2019-present, Vicarious, Inc.
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

sftp_path = value_for_platform_family(
  ['rhel', 'fedora'] => '/usr/libexec/openssh/sftp-server',
  ['debian'] => '/usr/lib/openssh/sftp-server',
)

# centos6 only supports 1...
if node.centos6?
  auth_keys = '.ssh/authorized_keys'
else
  auth_keys = [
    '.ssh/authorized_keys',
    '.ssh/authorized_keys2',
  ]
end

default['fb_ssh'] = {
  'enable_central_authorized_keys' => false,
  'manage_packages' => !node.windows?,
  'sshd_config' => {
    'PermitRootLogin' => false,
    'UsePAM' => true,
    'Subsystem sftp' => sftp_path,
    'AuthorizedKeysFile' => auth_keys,
  },
  'authorized_keys' => {},
  'authorized_keys_users' => [],
  'authorized_principals' => {},
  'authorized_principals_users' => [],
  'ssh_config' => {},
}
