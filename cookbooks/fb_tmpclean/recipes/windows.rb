#
# Cookbook Name:: fb_tmpclean
# Recipe:: Windows
#
# Copyright (c) Facebook, Inc. and its affiliates.
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

return unless platform_family?('windows')

# We place the actual ruby code to generate this in a lazy section, in order
# to have it evaluate at converge time rather than compile time, while still being
# idempotent - this way, all of our whyruns should automatically be happy, while keeping
# the code somewhat clean/readable/simple
file 'windows-tmpclean-ps-script' do
  path lazy { node['fb_tmpclean']['windows_script_location'] }
  # Only administrators should need access to this!
  rights :full_control, %w{Administrators}
  content lazy {
            (
              if node['fb_tmpclean']['dry_run'] == true
                windows_dry_run = ' -Whatif'
              else
                windows_dry_run = ''
              end

              folder_list = { 'c:\\windows\\temp' => node['fb_tmpclean']['default_files'],
                    'c:\\temp' => node['fb_tmpclean']['default_files'] }

              # Start with a random sleep, in order to avoid loading the entire IO subsystem
              # at once
              ps_script = 'start-sleep -Seconds (1..3600 | get-random)'
              ps_script << "\n"
              folder_list.merge!(node['fb_tmpclean']['directories'])
              # Note the default term is _hours_, not _seconds_ here - when I was
              # originally writing this, I acutally misread that!
              folder_list.each do |dir_glob, val|
                if val.to_s.end_with?('d')
                  term = "AddDays(-#{val.gsub('d', '')})"
                elsif val.to_s.end_with?('h')
                  term = "AddHours(-#{val.gsub('h', '')})"
                elsif val.to_s.end_with?('m')
                  term = "AddMinutes(-#{val.gsub('h', '')})"
                elsif val.to_s.end_with?('s')
                  term = "AddSeconds(-#{val.gsub('s', '')})"
                elsif val.to_i.to_s == val.to_s
                  term = "AddHours(-#{val})"
                else
                  fail "Unhandled time setting of #{val}"
                end

                if node['fb_tmpclean']['excludes'].empty?
                  exclude_term = ''
                else
                  exclude_term = "-exclude #{node['fb_tmpclean']['excludes'].join(',')}"
                end

                # Windows Get-Childitem does not unglob folders
                # use less than last access time as the gate for removing files
                #
                # Note that on 2016, you need both of these terms, though you do not on 2022!
                ps_script << <<-EOH
        if (Test-Path #{dir_glob}) {
          Get-Childitem -directory -path #{dir_glob} | % {Get-Childitem -file -recurse -Path $_.fullName #{exclude_term}} | ? {$_.LastAccessTime -lt (Get-Date).#{term}} | % {Remove-Item -Path $_.fullName #{windows_dry_run}}
          Get-Childitem -file -recurse -Path #{dir_glob} #{exclude_term} | ? {$_.LastAccessTime -lt (Get-Date).#{term}} | % {Remove-Item -Path $_.fullName #{windows_dry_run}}
        } \r\n
      EOH
              end
              ps_script
          ).to_s
          }
end

windows_task 'create-cleanup-task' do # rubocop:disable Chef/Meta/WindowsTaskAbsolutePaths
  # This is an absolute path - the linter is wrong
  command lazy {
            'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -File ' +
                (node['fb_tmpclean']['windows_script_location']).to_s
          }           # rubocop:disable Chef/Meta/WindowsTaskAbsolutePaths
  frequency :weekly
  start_time '02:20'
  start_when_available true
  task_name 'cleanup-temp-files'
  action [:create, :enable]
end
