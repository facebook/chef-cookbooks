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

default['fb_storage'] = {
  'manage_mdadm_conf' => true,
  'stop_and_zero_mdadm_for_format' => false,
  'hybrid_xfs_use_helper' => true,
  'fstab_use_labels' => true,
  'format' => {
    'firstboot_converge' => true,
    'firstboot_eraseall' => false,
    'hotswap' => true,
    'missing_filesystem_or_partition' => false,
    'mismatched_filesystem_or_partition' => false,
    'mismatched_filesystem_only' => false,
    'reprobe_before_repartition' => false,
  },
  'tuning' => {
    'scheduler' => nil,
    'queue_depth' => nil,
    'over_provisioning' => 'low',
    'over_provisioning_mapping' => {},
    'max_sectors_kb' => nil,
  },
  'format_options' => nil,
  '_num_non_root_devices' =>
    node.linux? ? FB::Storage.eligible_devices(node).count : nil,
  'arrays' => [],
  'devices' => [],
  '_handlers' => [
    FB::Storage::Handler::FioHandler,
    FB::Storage::Handler::MdHandler,
    FB::Storage::Handler::JbodHandler,
  ],
  '_clowntown_device_order_method' => nil,
  '_clowntown_override_file_method' => nil,
}
