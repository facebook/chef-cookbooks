#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
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

default_action :set
resource_name :fb_sdparm

def whyrun_supported?
  true
end

def get_sdparm_value(param, device)
  cmd = Mixlib::ShellOut.new("sdparm --get #{param} /dev/#{device}").run_command
  cmd.error!
  output = cmd.stdout
  # Match anything besides whitespace between '=' and paren
  re = /^#{param}\s+(\w+)\s/m
  match_obj = re.match(output)
  unless match_obj
    fail 'fb_sdparm: could not parse the output of sdparm'
  end

  match_data = match_obj[1]
  if match_data =~ /^\s*$/
    fail "fb_sdparm: could not get sdparm value for: #{param}"
  end
  match_data.to_s.strip
end

def set_sdparm_value(param, value, device, device_type)
  command = "sdparm --set #{param}=#{value}"
  # SATA devices do not support --save
  unless device_type == 'ATA'
    command << ' --save'
  end
  command << " /dev/#{device}"
  s = Mixlib::ShellOut.new(command).run_command
  s.error!
  new_val = get_sdparm_value(param, device)
  if new_val.to_s != value.to_s
    fail "fb_sdparm: drive still reports value as #{new_val}, " +
      "should be #{value}!"
  end
  Chef::Log.info("fb_sdparm: #{device}: set sdparm #{param} to #{value}.")
end

def cache_type_path_for_device(device)
  ::Dir.glob(
    "/sys/block/#{device}/device/scsi_disk/*/cache_type",
  ).first
end

def get_cache_type_desired_and_path(device)
  # key is a 2-item array of WCE, RCD
  cache_type_expected_values = {
    [0, 0] => 'write through',
    [0, 1] => 'none',
    [1, 0] => 'write back',
    [1, 1] => 'write back, no read (daft)',
  }
  wce = get_sdparm_value('WCE', device).to_i
  rcd = get_sdparm_value('RCD', device).to_i

  desired_cache_type = cache_type_expected_values[[wce, rcd]]
  cache_type_path = cache_type_path_for_device(device)
  [desired_cache_type, cache_type_path]
end

action :set do
  param_whitelist = [
    'RCD',
    'WCE',
  ]

  in_maint_disks = FB::Fstab.get_in_maint_disks
  Chef::Log.debug("in_maint_disks: #{in_maint_disks}")
  root_dev = node.device_of_mount('/')
  disks = node['block_device'].to_hash.reject do |dev, attrs|
    ['ram', 'loop', 'dm-'].include?(dev.delete('0-9')) ||
      (root_dev && root_dev.start_with?(dev)) ||
      dev.start_with?('nvme') ||
      dev.start_with?('md') ||
      dev.start_with?('fio') ||
      dev.start_with?('sr') ||
      attrs['model'] == 'XP6210-4B2048' || # nytro flash card
      in_maint_disks.include?("/dev/#{dev}")
  end
  Chef::Log.debug("disks: #{disks}")

  rotational_settings = node['fb_sdparm']['settings']['rotational'] ?
    node['fb_sdparm']['settings']['rotational'].to_hash :
    {}

  non_rotational_settings = node['fb_sdparm']['settings']['non-rotational'] ?
    node['fb_sdparm']['settings']['non-rotational'].to_hash :
    {}

  disks.each do |disk, details|
    if details['rotational'].to_i == 1
      settings = rotational_settings
    elsif details['rotational'].to_i.zero?
      settings = non_rotational_settings
    else
      # something is very wrong
      fail "fb_sdparm: disk #{disk} has no rotational value!"
    end

    settings.each do |param, desired_value|
      unless param_whitelist.include?(param)
        # do not let someone silently fail to set value due to typos
        fail "fb_sdparm: param #{param} is not yet supported by fb_sdparm!"
      end

      current_value = get_sdparm_value(param, disk)
      # Don't bother setting it if it's already correct
      if current_value.to_s == desired_value.to_s
        Chef::Log.debug("fb_sdparm: #{param} value already set to " +
                       "#{desired_value}.")
      else
        converge_by 'setting sdparm value' do
          set_sdparm_value(param, desired_value, disk, details['vendor'])
        end
      end
    end
    desired_cache_type, cache_type_path = get_cache_type_desired_and_path(disk)
    fb_sysfs cache_type_path do
      type :string
      value desired_cache_type + "\n"
    end
  end
end
