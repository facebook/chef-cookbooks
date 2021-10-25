# Copyright (c) 2021-present, Facebook, Inc.
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
  class SystemUpgrade
    def self.get_upgrade_command(node)
      package_manager = node.default_package_manager
      unless package_manager.include?('yum', 'dnf')
        fail "fb_system_upgrade: default package manager #{package_manager} " +
             'is not supported'
      end

      bin = which(package_manager)
      wrapper = node['fb_system_upgrade']['wrapper']
      if wrapper
        bin = "#{wrapper} #{bin}"
      end

      repos_cmd = ''
      repos = node['fb_system_upgrade']['repos']
      unless repos.empty?
        repos_cmd = "--disablerepo=* --enablerepo=#{repos.join(',')}"
      end

      exclude_cmd = ''
      exclude_pkgs = node['fb_system_upgrade']['exclude_packages']

      unless exclude_pkgs.empty?
        exclude_cmd << "-x #{exclude_pkgs.join(' -x ')}"
      end

      upgrade_cmd = "#{bin} #{repos_cmd} upgrade -y #{exclude_cmd}"
      log = node['fb_system_upgrade']['log']
      cmd = "date &>> #{log}; #{upgrade_cmd} &>> #{log}"

      cmd
    end
  end
end
