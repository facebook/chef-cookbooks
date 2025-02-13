#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

spamd_sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => {
    'spamdoptions' => '-c -m5 -H --razor-home-dir="/var/lib/razor/" ' +
      '--razor-log-file="sys-syslog"',
  },
  ['debian'] => {
    'options' => '--create-prefs --max-children 5',
  },
)

sa_sysconfig = value_for_platform_family(
  ['rhel', 'fedora'] => {
    'options' => '',
  },
  ['debian'] => {},
)

default['fb_spamassassin'] = {
  'local' => {
    'rewrite_header Subject' => '[SPAM]',
    'trusted_networks' => [],
    'required_score' => '5.0',
    'use_bayes' => 1,
    'bayes_path' => '/var/lib/spamassassin/bayes/bayes',
    'bayes_file_mode' => '0660',
    'bayes_auto_learn' => 1,
    'bayes_ignore_header' => [
      'X-Bogosity',
      'X-Spam-Flag',
      'X-Spam-Status',
      'X-Spam-Checker-Version',
    ],
  },
  'spamd_sysconfig' => spamd_sysconfig,
  'sa_sysconfig' => sa_sysconfig,
  'preserve_os_pre_files' => true,
  'plugins' => {
    'Mail::SpamAssassin::Plugin::URIDNSBL' => nil,
    'Mail::SpamAssassin::Plugin::SPF' => nil,
  },
  'enable_compat' => {
    'welcomelist_blocklist' => true,
  },
  'enable_update_job' => true,
}
