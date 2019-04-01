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
