# Copyright (c) Meta Platforms, Inc. and affiliates.
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

require './spec/spec_helper'
recipe 'fb_sysfs::default', :unsupported => [:mac_os_x] do |_tc|

  describe 'fb_sysfs' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        :platform => 'centos',
        :version => '8',
      ) do |node|
        node.default['fb_sysfs']['_set_on_boot']['foo'] = 'bar'
      end.converge(described_recipe)
    end

    let(:non_sysfs_chef_run) do
      ChefSpec::SoloRunner.new(
        :platform => 'centos',
        :version => '8',
      ) do |node|
        node.default['fb_sysfs']['_set_on_boot'] = {}
      end.converge(described_recipe)
    end

    it 'creates template when fed fb_sysfs[_set_on_boot] value' do
      # having trouble checking whats in the file because this returns a delayed evaluator obj instead of the content.
      expect(chef_run).to render_file('/etc/sysfs_files_on_boot')
    end

    it 'creates empty template when fb_sysfs[_set_on_boot] value is not set' do
      expect(non_sysfs_chef_run).to create_template('/etc/sysfs_files_on_boot').with({})
    end
  end
end
