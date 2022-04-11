#
# Copyright (c) 2022-present, Meta, Inc.
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

windows_drive = ENV['SYSTEMDRIVE'] || 'C:'
version_filepath = windows_drive + '\opt\td-agent-bit\VERSION.txt'
binary_filepath = windows_drive + '\opt\td-agent-bit\bin\fluent-bit.exe'

fluentbit_is_installed = File.exist?(binary_filepath)
existing_version = nil
if File.exist?(version_filepath)
  existing_version = IO.read(version_filepath)
end

windows_service 'FluentBit' do
  only_if { node['fb_fluentbit']['manage_packages'] }
  not_if do
    fluentbit_is_installed &&
    existing_version == node['fb_fluentbit']['windows_package']['version']
  end
  action :stop
end

windows_package 'td-agent-bit' do
  only_if { node['fb_fluentbit']['manage_packages'] }
  not_if do
    fluentbit_is_installed &&
    existing_version == node['fb_fluentbit']['windows_package']['version']
  end
  source lazy { node['fb_fluentbit']['windows_package']['source'] }
  checksum lazy { node['fb_fluentbit']['windows_package']['checksum'] }
  options '/S /D=C:\opt\td-agent-bit'
  action :install
end

file version_filepath do
  only_if { node['fb_fluentbit']['manage_packages'] }
  not_if do
    fluentbit_is_installed &&
    existing_version == node['fb_fluentbit']['windows_package']['version']
  end
  content lazy { node['fb_fluentbit']['windows_package']['version'] }
  action :create
  rights :full_control, 'Administrators'
end

windows_service 'FluentBit' do
  action [:create]
  binary_path_name windows_drive + '\opt\td-agent-bit\bin\fluent-bit.exe' +
    ' -c ' + windows_drive + '\opt\td-agent-bit\conf\fluent-bit.conf'
  description 'Logging and metrics processor and forwarder'
  startup_type :automatic
end
