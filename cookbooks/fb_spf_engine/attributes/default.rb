#
# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2026-present, Phil Dibowitz
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

rundir = '/run/pyspf-milter'

default['fb_spf_engine'] = {
  'manage_packages' => true,
  'config' => {
    'debugLevel' => 1,
    # confusingly, 1 means "actually reject"
    'TestOnly' => 1,
    'HELO_reject' => 'Fail',
    'Mail_From_reject' => 'Fail',
    'PermError_reject' => 'False',
    'TempError_Defer' => 'False',
    'skip_addresses' => [
      '127.0.0.0/8',
      '::ffff:127.0.0.0/104',
      '::1',
    ],
    'Socket' => "local:#{rundir}/pyspf-milter.sock",
    'PidFile' => "#{rundir}/pyspf-milter.pid",
    'UserID' => 'pyspf-milter',
    'InternalHosts' => ['127.0.0.1'],
  },
}
