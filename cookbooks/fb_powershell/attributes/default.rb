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

default['fb_powershell'] = {
  # Windows PowerShell
  'powershell' => {
    'manage' => false,
    'version' => nil,
  },
  # Opensource PowerShell aka Core
  'pwsh' => {
    'manage' => false,
    'version' => nil,
  },
  # Manage the powershell.config.json used by PowerShell Core
  'manage_config' => false,
  'config' => {},
}
