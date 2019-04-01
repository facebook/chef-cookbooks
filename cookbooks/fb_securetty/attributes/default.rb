# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

ttys = [
  'console',
  'tty1',
  'tty2',
  'tty3',
  'tty4',
  'tty5',
  'tty6',
  'tty7',
  'tty8',
  'tty9',
  'tty10',
  'tty11',
]

if node.centos?
  ttys += [
    'vc/1',
    'vc/2',
    'vc/3',
    'vc/4',
    'vc/5',
    'vc/6',
    'vc/7',
    'vc/8',
    'vc/9',
    'vc/10',
    'vc/11',
  ]
end

default['fb_securetty'] = {
  'ttys' => ttys,
}
