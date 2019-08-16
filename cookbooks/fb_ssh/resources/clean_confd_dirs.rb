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

action_class do
  def determine_non_package_owned_configs(type)
    unowned_files = []
    files = Dir.glob("/etc/ssh/#{type}_config.d/*")
    return [] if files.empty?
    if rpm_based?
      s = Mixlib::ShellOut.new(['/bin/rpm', '-qf'] + files).run_command
      # RPM will exit zero if all files are owned by a package
      if s.exitstatus == 0
        return []
      end
      s.stdout.split("\n").each do |line|
        m = /file (.*) is not owned by any package/.match(line.strip)
        next unless m
        unowned_files << m[1]
      end
    elsif debian?
      s = Mixlib::ShellOut.new(['dpkg', '-S'] + files).run_command
      # dpkg will exit zero if all files are owned by a package
      if s.exitstatus == 0
        return []
      end
      # dpkg puts unfound files on stderr, not stdout
      s.stderr.split("\n").each do |line|
        m = /no path found matching pattern (.*)/.match(line.strip)
        next unless m
        unowned_files << m[1]
      end
    else
      Chef::Log.warning('No ability to cleanup /etc/ssh/ssh*.d/ files')
      return []
    end
    if unowned_files.empty?
      Chef::Log.error(
        "There were unowned files in /etc/ssh/#{type}_config.d but we " +
        'could not determine which ones',
      )
    end
    unowned_files
  end
end

action :clean_ssh_d do
  determine_non_package_owned_configs('ssh').each do |f|
    file f do
      action :delete
    end
  end
end

action :clean_sshd_d do
  determine_non_package_owned_configs('sshd').each do |f|
    file f do
      action :delete
    end
  end
end
