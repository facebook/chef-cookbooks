#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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

action :run do
  # hash structure isn't necessary stable, and the JSON generation
  # certainly isn't stable, so just relying in 'file' isn't enough
  # to ensure we're not regenerating a file that didn't need to change.
  #
  # Instead, compare the data directly.
  return unless node.run_state['fb_bind_dns_cachedata']
  prev = node.run_state['fb_bind_dns_cachedata']['prev'].to_h
  new = node.run_state['fb_bind_dns_cachedata']['new'].to_h
  if prev != new
    file FB::Bind::CACHE_FILE do
      owner node.root_user
      group node.root_group
      mode '0640'
      content JSON.generate(new) + "\n"
    end
  end
end
