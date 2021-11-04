# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

require './spec/spec_helper'
require_relative '../libraries/powershell'

recipe 'fb_powershell::linux', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run do
      allow(FB::PowerShell).to receive(:install_pwsh_path_list).and_return(
        ['/opt/microsoft/powershell/7'],
      )
    end
  end

  it 'should not install a package if attr is not set' do
    chef_run.converge(described_recipe)
    expect(chef_run).to nothing_package('upgrade powershell')
  end

  it 'should upgrade/install a package if attr set to true' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_powershell']['pwsh']['manage'] = true
    end
    expect(chef_run).to upgrade_package('upgrade powershell')
  end
end
