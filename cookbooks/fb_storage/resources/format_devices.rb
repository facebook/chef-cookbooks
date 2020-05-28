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

property :do_reprobe, [true, false]

action_class do
  include FB::Storage::FormatDevicesProvider
end

action :run do
  fb_storage_format_devices 'go again' do
    action :nothing
    do_reprobe false
    notifies :reload, 'ohai[filesystem]', :immediately
  end

  storage = FB::Storage.new(node)
  to_do = filesystems_to_format(storage)
  if to_do[:devices].empty? && to_do[:partitions].empty? &&
     to_do[:arrays].empty? && to_do[:fill_arrays].empty?
    Chef::Log.info(
      'fb_storage: No storage to converge, or no permission to do so',
    )
    # if the user asked us to converge everything we could and there was nothing
    # to do, clean up that file
    file FB::Storage::CONVERGE_ALL_FILE do
      action :delete
    end
  else
    Chef::Log.debug(
      "fb_storage: filesystems_to_format to do is #{to_do}",
    )
    if !to_do[:devices].empty? && new_resource.do_reprobe
      devices_to_reprobe = to_do[:devices].join(' ')
      Chef::Log.info("fb_storage: reprobing #{devices_to_reprobe} as requested")
      execute "reprobe #{devices_to_reprobe}" do
        command "partprobe #{devices_to_reprobe} && sleep 5"
        notifies :reload, 'ohai[filesystem]', :immediately
        notifies :run, 'fb_storage_format_devices[go again]', :immediately
      end
    else
      msg = []
      unless to_do[:devices].empty?
        msg << "Partitioning #{to_do[:devices]}"
      end
      unless to_do[:partitions].empty?
        msg << "Formatting #{to_do[:partitions]}"
      end
      converge_by msg.join(', ') do
        converge_storage(to_do, storage)
      end
    end
  end

  # No matter what, we pass the data onto fb_fstab - this isn't a change
  # fb_fstab will report any changes it makes when it runs.
  #
  # unless we're in firstboot_os, since we don't converge storage until we're in
  # firstboot_tier
  unless node.firstboot_os?
    storage.gen_fb_fstab(node).each do |name, data|
      node.default['fb_fstab']['mounts'][name] = data
    end
  end

  # Determine if the kernel has multi-queue support enabled
  kernel_ver = FB::Version.new(node['kernel']['release'])
  kernel_mq_ver = FB::Version.new('4.11')
  kernel_has_mq = kernel_ver >= kernel_mq_ver

  # Finally, set any tunables
  storage.config.each_key do |device|
    dev = FB::Storage.device_name_from_path(device)

    if node['fb_storage']['tuning']['scheduler'] # ~FC023
      fb_sysfs "/sys/block/#{dev}/queue/scheduler" do
        # Kernels prior to 4.11 do not have multi-queue support - t19377518
        not_if { dev.start_with?('nvme') && !kernel_has_mq }
        type :list
        value node['fb_storage']['tuning']['scheduler']
      end
    end

    if node['fb_storage']['tuning']['queue_depth'] # ~FC023
      fb_sysfs "/sys/block/#{dev}/device/queue_depth" do
        type :int
        value node['fb_storage']['tuning']['queue_depth']
      end
    end

    if node['fb_storage']['tuning']['discard_max_bytes'] # ~FC023
      fname = "/sys/block/#{dev}/device/discard_max_bytes"
      fb_sysfs fname do
        only_if do
          # Only enables this setting when file exists and
          # file has root write permission bit set
          # This is due to older kernels don't support any
          # change to this file, we can tell if this is supported
          # by checking if root write permission bit is set
          # We're using the bitwise operation because internally ruby uses
          # eaccess which seems to consider root able to write anything
          # regardless of mode bits.
          ::File.exist?(fname) && ::File.stat(fname).mode & 0200 == 128
        end
        type :int
        value node['fb_storage']['tuning']['discard_max_bytes']
      end
    end

    # put a hard maximum on max_sectors_kb for nvme devices by default
    # (see T22006954)
    ignore_failure = FB::Fstab.get_in_maint_disks.include?(dev)
    nvme_max_sectors = 8192
    max_sectors_kb =
      node['fb_storage']['tuning']['max_sectors_kb']
    begin
      max_hw_sectors_kb =
        ::File.read("/sys/block/#{dev}/queue/max_hw_sectors_kb").to_i
    rescue StandardError
      if ignore_failure
        next
      else
        raise
      end
    end

    if dev.start_with?('nvme')
      if !max_sectors_kb
        Chef::Log.warn(
          'fb_storage: max_sectors_kb unspecified for ' +
          "#{dev}, setting to #{nvme_max_sectors}.",
        )
        max_sectors_kb = nvme_max_sectors
      elsif max_sectors_kb > nvme_max_sectors
        Chef::Log.warn(
          "fb_storage: max_sectors_kb #{max_sectors_kb} exceeds " +
          "allowed nvme limit for #{dev}, setting to #{nvme_max_sectors}.",
        )
        max_sectors_kb = nvme_max_sectors
      end
    end

    if max_sectors_kb
      # set to the smaller of max_hw_sectors_kb and user chosen value
      if max_sectors_kb > max_hw_sectors_kb
        Chef::Log.warn(
          'fb_storage: max_sectors_kb is limited by ' +
          "max_hw_sectors_kb, using #{max_hw_sectors_kb} instead " +
          "of #{max_sectors_kb}",
        )
        max_sectors_kb = max_hw_sectors_kb
      end

      fb_sysfs "/sys/block/#{dev}/queue/max_sectors_kb" do
        type :int
        value max_sectors_kb
        ignore_failure ignore_failure
      end
    end
  end
end
