# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Vicarious, Inc.
# Copyright (c) 2021-present, Facebook, Inc.
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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
action_class do
  def get_current_config
    config = {}
    section = nil
    s = powershell_exec('w32tm /query /configuration')
    s.result.each do |line|
      case line
      when /^\[(.*)\]$/
        section = $1
        config[section] = {}
      when /^(\w+)\s*:\s*([^(]+) \(.*\)$/
        config[section][$1] = $2
      end
    end
    config
  end

  def set_ntp_servers
    execute 'set NTP servers' do
      command 'w32tm /configure /reliable:yes /syncfromflags:manual ' +
        "/manualpeerlist:#{node['fb_ntp']['servers'].join(',')} /update"
    end
  end
end

action :config do
  config = get_current_config
  want = node['fb_ntp']['servers']
  have = config['TimeProviders'].fetch('NtpServer', '').split(',')
  if Set.new(want) == Set.new(have)
    Chef::Log.debug('fb_ntp[windows_config]: NTP servers are correct')
  else
    Chef::Log.info(
      'fb_ntp[windows_config]: Changing NTP servers from ' +
      "#{have.join(', ')} to #{want.join(', ')}",
    )
    set_ntp_servers
  end
end
