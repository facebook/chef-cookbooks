# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

server_list = %w{
  time1.facebook.com
  time2.facebook.com
  time3.facebook.com
  time4.facebook.com
  time5.facebook.com
}

default['fb_chrony'] = {
  'manage_packages' => true,
  'servers' => server_list,
  'pools' => {},
  # https://chrony.tuxfamily.org/doc/3.4/chrony.conf.html
  'default_options' => %w{iburst},
  'config' => {
    # Record the rate at which the system clock gains/losses time.
    'driftfile' => '/var/lib/chrony/drift',
    # Allow the system clock to be stepped in the first three updates
    # if its offset is larger than 1 second.
    'makestep' => '1.0 3',
    # Enable kernel synchronization of the real-time clock (RTC).
    'rtcsync' => nil,
    # Enable logging
    'logdir' => '/var/log/chrony',
    # maximum amount of memory to support interleaved mode
    'clientloglimit' => '10485760',
  },
}
