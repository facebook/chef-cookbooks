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
LABEL=/ / ext4 defaults,discard 1 1
LABEL=/boot /boot ext3    defaults        1 2
/dev/sda2 swap swap    defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs /dev/shm tmpfs defaults,size=4G 0 0
EOF

recipe 'fb_fstab::default', :unsupported => [:mac_os_x] do |tc|
  let(:base_fstab_minimal) { base_contents }

  let(:base_fstab_with_userfs) do
    base_contents + "\nLABEL=foofy /mnt/foofy xfs defaults 0 0\n"
  end

  before(:each) do
    allow(FB::Fstab).to receive(:generate_base_fstab)
  end

  context 'missing labels are allowed' do
    # rubocop:disable Style/MultilineBlockChain
    let(:chef_run) do
      tc.chef_run do |node|
        if node['filesystem2']
          node.automatic['filesystem2'] = ohai(:filesystem2)
        else
          node.automatic['filesystem'] = ohai(:filesystem)
        end
      end.converge(described_recipe) do |node|
        node.default['fb_fstab']['mounts']['foofy'] = {
          'device' => 'LABEL=foofy',
          'mount_point' => '/mnt/foofy',
          'type' => 'xfs',
          'opts' => 'defaults,noatime',
          'pass' => 0,
          'allow_mount_failure' => true,
        }
      end
    end
    # rubocop:enable Style/MultilineBlockChain

    it 'generates a correct config for user filesystems' do
      allow(FB::Fstab).to receive(:base_fstab_contents).
        and_return(base_fstab_minimal)
      expect(chef_run).to render_file('/etc/fstab').
        with_content(tc.fixture('fstab_extra_label'))
    end

    it 'generates a correct config for base filesystems' do
      allow(FB::Fstab).to receive(:base_fstab_contents).
        and_return(base_fstab_with_userfs)
      expect(chef_run).to render_file('/etc/fstab').
        with_content(tc.fixture('fstab_extra_label'))
    end
  end

  context 'missing labels are not allowed' do
    # rubocop:disable Style/MultilineBlockChain
    let(:chef_run) do
      tc.chef_run(:step_into => ['template']) do |node|
        if node['filesystem2']
          node.automatic['filesystem2'] = ohai(:filesystem2)
        else
          node.automatic['filesystem'] = ohai(:filesystem)
        end
      end.converge(described_recipe) do |node|
        node.default['fb_fstab']['mounts']['foofy'] = {
          'device' => 'LABEL=foofy',
          'mount_point' => '/mnt/foofy',
          'type' => 'xfs',
          'opts' => 'defaults,noatime',
          'pass' => 0,
        }
      end
    end
    # rubocop:enable Style/MultilineBlockChain

    it 'should raise an error on user filesystems' do
      allow(FB::Fstab).to receive(:base_fstab_contents).
        and_return(base_fstab_minimal)
      expect { chef_run }.to raise_error(RuntimeError)
    end

    it 'should raise an error on base filesystems' do
      allow(FB::Fstab).to receive(:base_fstab_contents).
        and_return(base_fstab_with_userfs)
      expect { chef_run }.to raise_error(RuntimeError)
    end
  end
end
