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

# rubocop:disable Style/MultilineBlockChain

recipe 'fb_powershell::linux', :supported => [:centos7] do |tc|
  let(:profile) { '/opt/microsoft/powershell/7/profile.ps1' }

  before do
    allow(Dir).to receive(:glob).with('/opt/microsoft/powershell/[6789]*').
      and_return(['/opt/microsoft/powershell/7'])
    allow(FB::PowerShell).to receive(:install_pwsh_path_list).and_return(
      ['/opt/microsoft/powershell/7'],
    )
    allow(FB::PowerShell).to receive(:get_profile_path).and_return(profile)
  end

  let(:chef_run) do
    tc.chef_run(:step_into => ['fb_powershell_apply_config']) do
    end.converge(described_recipe) do |node|
      node.default['fb_powershell']['manage_config'] = true
      node.default['fb_powershell']['config'] = {
        'WindowsPowerShellCompatibilityModuleDenyList' =>  [
          'PSScheduledJob',
          'BestPractices',
          'UpdateServices',
        ],
        'Microsoft.PowerShell:ExecutionPolicy' => 'RemoteSigned',
      }
    end
  end

  it 'should render a json config file with the data passed in' do
    expect(chef_run).to render_file(
      '/opt/microsoft/powershell/7/powershell.config.json',
    ).with_content(
      tc.fixture('powershell.config.json'),
    )
  end
end

# # rubocop:enable Style/MultilineBlockChain
