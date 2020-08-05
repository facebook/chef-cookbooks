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

if node.systemd? || node.macos?
  sysconfig = {}
else
  syslogd_options_var = value_for_platform_family(
    ['rhel', 'fedora'] => 'SYSLOGD_OPTIONS',
    'debian' => 'RSYSLOGD_OPTIONS',
  )
  sysconfig = {
    'vars' => {
      syslogd_options_var => '',
    },
    'extra_lines' => [],
  }
end

# Add in some reasonable defaults for all syslog.confs
default['fb_syslog'] = {
  'syslog-entries' => {
    'base_messages' => {
      # Will commentify comments later
      'comment' => 'Log anything info level or higher. A lot ' +
                   'of things go into their own file.',
      'selector' => '*.info;mail,authpriv,cron,' +
                    'local2,local3,local5,local6.none',
      'action' => '-/var/log/messages',
    },
    'mail' => {
      'comment' => 'Log all the mail messages in one place.',
      'selector' => 'mail.*',
      'action' => '-/var/log/maillog',
    },
    'cron' => {
      'comment' => 'Log all cron messages in one place.',
      'selector' => 'cron.*',
      'action' => '-/var/log/cron',
    },
    'emergency' => {
      'comment' => 'Everybody gets emergency messages',
      'selector' => '*.emerg',
      'action' => '*',
    },
    'news' => {
      'comment' => 'Save news errors of level crit and higher ' +
                   'in a special file.',
      'selector' => 'uucp,news.crit',
      'action' => '-/var/log/spooler',
    },
    'boot' => {
      'comment' => 'Among other places, boot messages always go to boot.log',
      'selector' => 'local7.*',
      'action' => '-/var/log/boot.log',
    },
  },
  'rsyslog_server' => false,
  'rsyslog_server_address' => nil,
  'rsyslog_rulesets' => {},
  'rsyslog_nonruleset_ports' => {
    'tcp' => [],
    'udp' => [],
  },
  'rsyslog_early_lines' => [],
  'rsyslog_late_lines' => [],
  'rsyslog_additional_sockets' => [],
  'rsyslog_facilities_sent_to_remote' => [],
  'rsyslog_port' => '514',
  'rsyslog_upstream' => '',
  'rsyslog_report_suspension' => false,
  'rsyslog_stats_logging' => false,
  'rsyslog_use_omprog_force' => false,
  'rsyslog_omprog_binary_args' => [],
  'sysconfig' => sysconfig,
  '_enable_syslog_socket_override' => true,
}
