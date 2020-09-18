# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

default_action :request_nw_changes

action :request_nw_changes do
  file FB::NetworkScripts::NW_CHANGES_NEEDED do
    action :touch
  end
end

all_signal_files = [
  FB::NetworkScripts::NW_CHANGES_NEEDED,
  FB::NetworkScripts::NW_CHANGES_ALLOWED,
]

action :cleanup_signal_files_when_no_change_required do
  unless node['fb_network_scripts']['_perm_requested']
    all_signal_files.each do |the_file|
      file "cleanup no longer required signal file #{the_file}" do
        path the_file
        action :delete
      end
    end
  end
end
