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

add_drivers = []

if node.virtual?
  add_drivers += %w{
    virtio
    virtio_blk
    virtio_ring
    virtio_pci
    virtio_scsi
  }
end

default['fb_dracut'] = {
  'conf' => {
    'add_dracutmodules' => [],
    'drivers' => [],
    'add_drivers' => add_drivers,
    'omit_drivers' => [],
    'filesystems' => [],
    'drivers_dir' => [],
    'fw_dir' => [],
    'do_strip' => nil,
    'hostonly' => true,
    'mdadmconf' => true,
    'lvmconf' => true,
    'kernel_only' => nil,
    'no_kernel' => nil,
    'early_microcode' => true,
  },
}
