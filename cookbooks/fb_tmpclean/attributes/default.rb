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

excludes = []
directories = {}
if node.rhel_family?
  excludes = [
    '.X11-unix',
    '.XIM-unix',
    '.font-unix',
    '.ICE-unix',
    '.Test-unix',
  ]
elsif node.debian_family?
  excludes = [
    '.X*-{lock,unix,unix/*}',
    'ICE-{unix,unix/*}',
    '.iroha_{unix,unix/*}',
    '.ki2-{unix,unix/*}',
    'lost+found',
    'journal.dat',
    'quota.{user,group}',
  ]
  directories = {
    '/tmp/.' => 240,
  }
end

default['fb_tmpclean'] = {
  'default_files' => 240,
  'directories' => directories,
  'timestamptype' => 'mtime',
  'extra_lines' => [],
  'excludes' => excludes,
  'remove_special_files' => false,
  'manage_packages' => true,
  'windows_script_location' => 'c:\\chef\\fbit\\cleanup-temp.ps1',
}
