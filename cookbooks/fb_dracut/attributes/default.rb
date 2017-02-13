# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
  },
}
