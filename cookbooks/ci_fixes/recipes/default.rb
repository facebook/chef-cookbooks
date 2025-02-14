#
# Cookbook Name:: ci_fixes
# Recipe:: default
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

node.default['fb_systemd']['logind']['enable'] = false

# older versions of rsyslog try to call close() on every _possible_ fd
# as limited by ulimit -n, which can take MINUTES to start. So drop this
# number for CI: https://github.com/rsyslog/rsyslog/issues/5158
if node.centos_max_version?(9)
  node.default['fb_limits']['*']['nofile'] = {
    'hard' => '1024',
    'soft' => '1024',
  }
end

# postfix hasn't setup it's chroot on rsyslog's first startup and
# thus it fails in containers on firstboot, so override postfix
# telling syslog to look at its socket. Why this is an issue only
# on CentOS, I do not know
whyrun_safe_ruby_block 'ci fix for postfix/syslog' do
  only_if { node.centos? }
  block do
    node.default['fb_syslog']['rsyslog_additional_sockets'] = []
  end
end

# create the certs the default apache looks at
execute 'create certs' do
  only_if { node.centos? }
  command 'openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 ' +
    '-nodes -out /etc/pki/tls/certs/localhost.crt ' +
    '-keyout /etc/pki/tls/private/localhost.key ' +
    '-subj "/C=US/ST=California/L=Some City/O=Some Org/CN=test"'
end

# GH Runner's forced apparmor doesn't let binaries write to
# /run/systemd/notify, so tell the unit not to try
# why this seems to be issue on CentOS, I do not know
fb_systemd_override 'syslog-no-systemd' do
  only_if { node.centos? }
  unit_name 'rsyslog.service'
  content({
            'Service' => {
              'Type' => 'simple',
            },
          })
end
