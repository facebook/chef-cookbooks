# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
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

require './spec/spec_helper'
require_relative '../libraries/default'
require_relative '../libraries/provider'

def ohai(key)
  JSON.parse(
    File.read(File.expand_path("#{key}.json", File.dirname(__FILE__))),
  )
end
base_contents = <<EOF
UUID=28137926-9c39-44c0-90d3-3b158fc97ff9 /                       ext4    defaults,discard 1 1
UUID=9ebfe8b9-c188-4cda-8383-393deb0ac59c /boot                   ext3    defaults        1 2
UUID=2ace4f5f-c8c5-4d3a-a027-d12076bdab0c swap                    swap    defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs /dev/shm tmpfs defaults,size=4G 0 0
EOF

recipe 'fb_fstab::default', :unsupported => [:mac_os_x] do |tc|
  let(:base_fstab) { base_contents }

  before(:each) do
    allow(FB::Fstab).to receive(:generate_base_fstab)
    allow(FB::Fstab).to receive(:base_fstab_contents).and_return(base_fstab)
  end

  context 'no custom header' do
    # rubocop:disable Style/MultilineBlockChain
    let(:chef_run) do
      tc.chef_run do |node|
        if node['filesystem2']
          node.automatic['filesystem2'] = ohai(:filesystem2)
        else
          node.automatic['filesystem'] = ohai(:filesystem)
        end
      end
    end
    # rubocop:enable Style/MultilineBlockChain

    it 'generates a correct comment section' do
      chef_run.converge(described_recipe)
      expect(chef_run).to render_file('/etc/fstab').
        with_content(tc.fixture('fstab'))
    end
  end

  context 'with custom header' do
    # rubocop:disable Style/MultilineBlockChain
    let(:chef_run) do
      tc.chef_run do |node|
        if node['filesystem2']
          node.automatic['filesystem2'] = ohai(:filesystem2)
        else
          node.automatic['filesystem'] = ohai(:filesystem)
        end
      end
    end
    # rubocop:enable Style/MultilineBlockChain

    it 'generates a correct comment section' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_fstab']['custom_comment_headers'] = [
          'Custom header line 1',
          'and line 2',
        ]
      end
      expect(chef_run).to render_file('/etc/fstab').
        with_content(tc.fixture('fstab_custom_headers'))
    end
  end
end
