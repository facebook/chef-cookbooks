#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

def get_hdparm_value(param, device)
  cmd = Mixlib::ShellOut.new("hdparm #{param} #{device}").run_command
  cmd.error!
  output = cmd.stdout
  # Strip whitespace to make regex much cleaner
  output.gsub!(/\s+/, '')
  # Match anything besides whitespace between '=' and paren
  re = /=([^\s])+\(/m
  match_obj = re.match(output)
  unless match_obj
    fail 'Could not parse the output of hdparm'
  end

  match_data = match_obj[1]
  if match_data =~ /^\s*$/
    fail "Could not get hdparm value for: #{param}"
  end
  match_data.to_s.strip
end

def set_hdparm_values(values, device)
  values.each do |key, val|
    command = "hdparm #{key} #{val} #{device}"
    s = Mixlib::ShellOut.new(command).run_command
    s.error!
    Chef::Log.info("Successfully set hdparm #{key} to #{val}.")
  end
end

action :set do
  values_to_set = {}
  supported_opts = ['-W']
  root_device = node.device_of_mount('/')
  if root_device.start_with?('/dev/fio', '/dev/vd', '/dev/nvme')
    Chef::Log.warn("Device #{root_device} is not supported by fb_hdparm.")
    return
  end
  settings = node['fb_hdparm']['settings'].to_hash
  settings.each do |option, desired_value|
    unless supported_opts.include?(option)
      Chef::Log.warn("Option #{option} is not yet supported by fb_hdparm." +
                     'Skipping.')
      next
    end
    desired_value = desired_value.to_s
    current_value = get_hdparm_value(option, root_device)
    # Don't bother setting it if it's already correct
    if current_value == desired_value
      Chef::Log.debug("hdparm #{option} value already set to " +
                     "#{desired_value}.")
    else
      values_to_set[option] = desired_value
    end
  end
  if values_to_set.empty?
    Chef::Log.debug('All hdparm params are already set correctly')
  else
    converge_by "Set hdparm values for #{root_device}" do
      set_hdparm_values(values_to_set, root_device)
    end
  end
end
