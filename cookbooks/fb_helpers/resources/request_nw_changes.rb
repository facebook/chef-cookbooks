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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :request_nw_changes

action :request_nw_changes do
  file FB::Helpers::NW_CHANGES_NEEDED do
    owner node.root_user
    group node.root_group
    mode '0644'
    action :touch
    content lazy {
              node['fb_helpers']['_nw_perm_changes_requested'].map do |resource, diff|
                "#{resource} requesting to change:\n#{diff}"
              end.join("\n").gsub(/\\n/, "\n").concat("\n")
            }
  end
end

all_signal_files = [
  FB::Helpers::NW_CHANGES_NEEDED,
  FB::Helpers::NW_CHANGES_ALLOWED,
]

action :cleanup_signal_files_when_no_change_required do
  unless node['fb_helpers']['_nw_perm_requested']
    all_signal_files.each do |the_file|
      file "cleanup no longer required signal file #{the_file}" do
        path the_file
        action :delete
      end
    end
  end
end
