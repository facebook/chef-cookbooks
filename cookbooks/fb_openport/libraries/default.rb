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

module FB
  class Openport
    # Helper function to assemble base URL. Obviously not runtime safe, so
    # make sure to run it at runtime, not compile time.
    def self.download_url(node)
      arch = node['cpu']['architecture']
      if ChefUtils.fedora_derived?
        vsep = '-'
        asep = '.'
        ext = 'rpm'
      else
        vsep = '_'
        asep = '_'
        ext = 'deb'
        arch = arch == 'x86_64' ? 'amd64' : arch
      end
      version = node['fb_openport']['version']
      base_url = node['fb_openport']['download_base_url']
      "#{base_url}/openport#{vsep}#{version}#{asep}#{arch}.#{ext}"
    end
  end
end
