# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

use_inline_resources

def whyrun_supported?
  true
end

action :remove do
  unless node['ipc']
    fail 'Unable to find IPC information from ohai, skipping remove'
  end

  key = new_resource.id.to_i

  if new_resource.type == :shm
    unless node['ipc']['shm']
      fail 'Unable to find shared memory information from ohai, skipping remove'
    end
    execute "remove shmid #{key}" do
      only_if { node['ipc']['shm'][key] }
      command "/usr/bin/ipcrm -m #{key}"
    end
  end
end
