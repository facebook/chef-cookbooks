#
# Copyright (c) 2012-present, Facebook, Inc.
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

default['fb_ntp'] = {
  'servers' => server_list,
  'ntpd_options' => '-p /var/run/ntpd.pid',
  'ntpdate_options' => '-U ntp -t 3 -s -b',
  'ntpdate_retries' => 3,
  'sync_hwclock' => true,
  'ntp_conf_server_options' => 'iburst',
  'skip_comments' => false,
  'acl_entries' => [],
  'monitor' => false,
  'manage_packages' => true,
}
