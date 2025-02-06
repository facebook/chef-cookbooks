# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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
# TODO(dcrosby)
# rubocop:disable Chef/Meta/DontUseFileUtils
require 'chef/node'
# we know relative_requires is bad, but it allows us to handle pathing
# differences between internal repo and github
require_relative '../libraries/default'
require_relative '../libraries/provider'

describe 'FB::Fstab' do
  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end
  full_contents = <<EOF
#
# /etc/fstab
# Created by anaconda on Mon May 13 06:43:59 2013
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=28137926-9c39-44c0-90d3-3b158fc97ff9 /                       ext4    defaults,discard 1 1
UUID=9ebfe8b9-c188-4cda-8383-393deb0ac59c /boot                   ext3    defaults        1 2
UUID=2ace4f5f-c8c5-4d3a-a027-d12076bdab0c swap                    swap    defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs /dev/shm tmpfs defaults,size=4G 0 0
/dev/crazy /mount/foo xfs defaults 0 0
EOF
  base_contents = <<EOF
UUID=28137926-9c39-44c0-90d3-3b158fc97ff9 /                       ext4    defaults,discard 1 1
UUID=9ebfe8b9-c188-4cda-8383-393deb0ac59c /boot                   ext3    defaults        1 2
UUID=2ace4f5f-c8c5-4d3a-a027-d12076bdab0c swap                    swap    defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs /dev/shm tmpfs defaults,size=4G 0 0
EOF

  context 'generate_base_fstab' do
    it 'should not regenerate base fstab' do
      expect(File).to receive(:exist?).with(FB::Fstab::BASE_FILENAME).
        and_return(true)
      expect(File).to receive(:size?).with(FB::Fstab::BASE_FILENAME).
        and_return(true)
      expect(File).not_to receive(:open)
      FB::Fstab.generate_base_fstab
    end
    it 'should generate new base fstab' do
      expect(File).to receive(:exist?).with(FB::Fstab::BASE_FILENAME).
        and_return(false)
      expect(FileUtils).to receive(:cp).and_return(nil)
      expect(FileUtils).to receive(:chmod).and_return(
        ['/root/fstab.before_fb_fstab'],
      )
      expect(File).to receive(:read).and_return(full_contents)
      expect(File).to receive(:write).with(FB::Fstab::BASE_FILENAME,
                                           base_contents)
      FB::Fstab.generate_base_fstab
    end
  end

  context 'determine_base_fstab_entries' do
    it 'should regenerate base fstab properly' do
      expect(FB::Fstab.determine_base_fstab_entries(full_contents)).
        to eq(base_contents)
    end
    it 'should not include exta tmpfs mounts' do
      expect(FB::Fstab.determine_base_fstab_entries(full_contents)).
        to eq(base_contents)
    end
  end

  context 'autofs_parent' do
    before(:each) do
      node.default[attr_name]['by_pair']['foo:/bar/baz,/mnt/foo'] = {
        'device' => 'foo:/bar/baz',
        'mount' => '/mnt/foo',
        'fs_type' => 'autofs',
      }
    end
    it 'should return the autofs parent when one exists' do
      expect(FB::Fstab.autofs_parent('/mnt/foo/bar', node)).to eq('/mnt/foo')
    end
    it 'should return the autofs dir when same as mount' do
      expect(FB::Fstab.autofs_parent('/mnt/foo', node)).to eq('/mnt/foo')
    end
    it 'should return false if no conflict with autofs' do
      expect(FB::Fstab.autofs_parent('/mnt/waka', node)).to eq(false)
    end
  end
  context 'label_to_device' do
    it 'should find the right label' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'label' => 'label1',
        },
        'bar' => {
          'label' => 'label2',
        },
      }
      expect(FB::Fstab.label_to_device('label2', node)).to eq('bar')
    end
    it 'should not get confused by fs without label' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'uuid' => 'uuid1',
        },
        'bar' => {
          'label' => 'label2',
        },
      }
      expect(FB::Fstab.label_to_device('label2', node)).to eq('bar')
    end
    it 'should fail on missing label' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'uuid' => 'uuid1',
        },
        'bar' => {
          'label' => 'label2',
        },
      }
      expect do
        FB::Fstab.label_to_device('label1', node)
      end.to raise_error(RuntimeError)
    end
  end
  context 'uuid_to_device' do
    it 'should find the right uuid' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'uuid' => 'uuid1',
        },
        'bar' => {
          'uuid' => 'uuid2',
        },
      }
      expect(FB::Fstab.uuid_to_device('uuid2', node)).to eq('bar')
    end
    it 'should not get confused by fs without uuid' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'label' => 'label1',
        },
        'bar' => {
          'uuid' => 'uuid2',
        },
      }
      expect(FB::Fstab.uuid_to_device('uuid2', node)).to eq('bar')
    end
    it 'should fail on missing uuid' do
      node.default[attr_name]['by_device'] = {
        'foo' => {
          'label' => 'label1',
        },
        'bar' => {
          'uuid' => 'uuid2',
        },
      }
      expect do
        FB::Fstab.uuid_to_device('uuid1', node)
      end.to raise_error(RuntimeError)
    end
  end
  context 'parse_in_maint_file' do
    it 'should return an empty array if file does not exist' do
      expect(File).to receive(:exist?).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(false)
      expect(FB::Fstab.parse_in_maint_file(FB::Fstab::IN_MAINT_DISKS_FILENAME)).
        to eq([])
    end
    it 'should delete stale files' do
      stat = double('FSstat')
      expect(stat).to receive(:mtime).and_return(Time.new - 60 * 60 * 24 * 8)
      expect(File).to receive(:exist?).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(true)
      expect(File).to receive(:stat).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(stat)
      expect(File).to receive(:unlink).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(true)
      expect(FB::Fstab.parse_in_maint_file(FB::Fstab::IN_MAINT_DISKS_FILENAME)).
        to eq([])
    end
  end
  context 'get_in_maint_mounts' do
    it 'should canonicalize mount paths' do
      expect(FB::Fstab).to receive(:parse_in_maint_file).
        with(FB::Fstab::IN_MAINT_MOUNTS_FILENAME).and_return(['/mnt/d0/'])
      expect(FB::Fstab.get_in_maint_mounts).to eq(['/mnt/d0'])
    end
  end
  context 'get_unmasked_base_mounts' do
    let(:default_ret) do
      {
        '/dev/sda1' => {
          'mount_point' => '/',
          'type' => 'ext4',
          'opts' => 'defaults,discard',
          'dump' => '1',
          'pass' => '1',
        },
        '/dev/sda2' => {
          'mount_point' => '/boot',
          'type' => 'ext3',
          'opts' => 'defaults',
          'dump' => '1',
          'pass' => '2',
        },
        '/dev/sda3' => {
          'mount_point' => 'swap',
          'type' => 'swap',
          'opts' => 'defaults',
          'dump' => '0',
          'pass' => '0',
        },
        'devpts' => {
          'mount_point' => '/dev/pts',
          'type' => 'devpts',
          'opts' => 'gid=5,mode=620',
          'dump' => '0',
          'pass' => '0',
        },
        'sysfs' => {
          'mount_point' => '/sys',
          'type' => 'sysfs',
          'opts' => 'defaults',
          'dump' => '0',
          'pass' => '0',
        },
        'proc' => {
          'mount_point' => '/proc',
          'type' => 'proc',
          'opts' => 'defaults',
          'dump' => '0',
          'pass' => '0',
        },
        'tmpfs' => {
          'mount_point' => '/dev/shm',
          'type' => 'tmpfs',
          'opts' => 'defaults,size=4G',
          'dump' => '0',
          'pass' => '0',
        },
      }
    end
    before do
      node.default[attr_name]['by_device'] = {
        '/dev/sda1' => {
          'mounts' => ['/'],
          'fs_type' => 'ext4',
          'uuid' => '28137926-9c39-44c0-90d3-3b158fc97ff9',
          'label' => '/',
        },
        '/dev/sda2' => {
          'mounts' => ['/boot'],
          'fs_type' => 'ext3',
          'uuid' => '9ebfe8b9-c188-4cda-8383-393deb0ac59c',
          'label' => '/boot',
        },
        '/dev/sda3' => {
          'fs_type' => 'swap',
          'uuid' => '2ace4f5f-c8c5-4d3a-a027-d12076bdab0c',
        },
      }
      node.default['fb_fstab']['mounts'] = {}
      node.default['fb_swap']['enabled'] = true
    end
    it 'should parse base mounts correctly' do
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      m = FB::Fstab.get_unmasked_base_mounts(:hash, node)
      expect(m).to eq(default_ret)
      m = FB::Fstab.get_unmasked_base_mounts(:lines, node).join("\n") + "\n"
      expect(m).to eq(base_contents)
    end
    it 'should drop swap if masked' do
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      node.default['fb_fstab']['exclude_base_swap'] = true
      m = FB::Fstab.get_unmasked_base_mounts(:hash, node)
      default_ret.delete('/dev/sda3')
      expect(m).to eq(default_ret)
    end
    it 'should not return overridden mounts' do
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      node.default['fb_fstab']['mounts'] = {
        'phild override' => {
          'device' => '/dev/sda1',
          'mount_point' => '/',
          'type' => 'ext4',
          'opts' => 'defaults,discard,noatume',
          'dump' => '1',
          'pass' => '1',
        },
      }
      m = FB::Fstab.get_unmasked_base_mounts(:hash, node)
      default_ret.delete('/dev/sda1')
      expect(m).to eq(default_ret)
    end
    it 'should raise an exception if base has bad label' do
      contents = base_contents +
        "LABEL=nonexistent / ext4 opts 0 0\n"
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(contents)
      expect { FB::Fstab.get_unmasked_base_mounts(:hash, node) }.
        to raise_error(RuntimeError)
    end
    it 'should not raise an exception if base has bad UUID overwridden' do
      contents = base_contents +
        "UUID=nonexistent / ext4 opts 0 0\n"
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(contents)
      node.default['fb_fstab']['mounts'] = {
        'phild override' => {
          'device' => 'LABEL=/',
          'mount_point' => '/',
          'type' => 'ext4',
          'opts' => 'defaults,discard,noatume',
          'dump' => '1',
          'pass' => '1',
        },
      }
      m = FB::Fstab.get_unmasked_base_mounts(:hash, node)
      default_ret.delete('/dev/sda1')
      expect(m).to eq(default_ret)
    end
    it 'should raise an exception if user specifies bad label' do
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      node.default['fb_fstab']['mounts'] = {
        'phild mount' => {
          'device' => 'LABEL=nonexistent',
          'mount_point' => '/stuff',
          'type' => 'ext4',
          'opts' => 'defaults,discard,noatume',
          'dump' => '1',
          'pass' => '1',
        },
      }
      expect { FB::Fstab.get_unmasked_base_mounts(:hash, node) }.
        to raise_error(RuntimeError)
    end
    it 'should not raise an exception if user specifies bad label and' +
       'allow_failure' do
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      node.default['fb_fstab']['mounts'] = {
        'phild mount' => {
          'device' => 'LABEL=nonexistent',
          'mount_point' => '/stuff',
          'type' => 'ext4',
          'opts' => 'defaults,discard,noatume',
          'dump' => '1',
          'pass' => '1',
          'allow_mount_failure' => true,
          'allow_remount_failure' => true,
        },
      }
      m = FB::Fstab.get_unmasked_base_mounts(:hash, node)
      expect(m).to eq(default_ret)
    end
  end
end

describe 'FB::FstabProvider', :include_provider do
  include FB::FstabProvider

  let(:node) { Chef::Node.new }
  let(:attr_name) do
    if node['filesystem2']
      'filesystem2'
    else
      'filesystem'
    end
  end
  before do
    node.default[attr_name] = {
      'by_pair' => {},
      'by_device' => {},
      'by_mountpoint' => {},
    }
  end

  context 'compare_opts' do
    before(:each) do
      node.default['fb_fstab']['ignorable_opts'] = []
    end
    it 'should find identical things identical' do
      expect(compare_opts(
               'rw,size=1G',
               'rw,size=1G',
      )).to eq(true)
    end
    it 'should find different-order strings identical' do
      expect(compare_opts(
               'size=1G,rw',
               'rw,size=1G',
      )).to eq(true)
    end
    it 'should find arrays and strings identical' do
      expect(compare_opts(
               'rw,size=1G',
               ['size=1G', 'rw'],
      )).to eq(true)
    end
    it 'should treat missing-rw opts as identical' do
      expect(compare_opts(
               'size=1G',
               ['size=1G', 'rw'],
      )).to eq(true)
    end
    it 'should not treat ro and rw as the same' do
      expect(compare_opts(
               'size=1G,ro',
               ['size=1G', 'rw'],
      )).to eq(false)
    end
    it 'should handle arrays the same' do
      expect(compare_opts(
               ['size=1G'],
               ['size=1G', 'rw'],
      )).to eq(true)
    end
    it 'should catch different sizes as different opts' do
      expect(compare_opts(
               ['rw', 'size=2G'],
               ['size=1G', 'rw'],
      )).to eq(false)
    end
    it 'should honor ignored string opts' do
      node.default['fb_fstab']['ignorable_opts'] << 'nofail'
      expect(compare_opts(
               ['rw', 'nofail', 'noatime'],
               ['rw', 'noatime'],
      )).to eq(true)
    end
    it 'should honor ignored regex opts' do
      node.default['fb_fstab']['ignorable_opts'] << /^addr=.*/
      expect(compare_opts(
               ['rw', 'addr=10.0.0.1', 'noatime'],
               ['rw', 'noatime'],
      )).to eq(true)
    end
    it 'should honor skipped options when provided' do
      expect(compare_opts(
               ['rw', 'size=1G', 'inode64'],
               ['size=1G', 'rw'],
               ['inode64'],
      )).to eq(true)
    end
    it 'should normalize size opts' do
      expect(compare_opts(
               'size=4K',
               'size=4096',
      )).to eq(true)
      expect(compare_opts(
               'size=4M',
               'size=4194304',
      )).to eq(true)
      expect(compare_opts(
               'size=4g',
               'size=4294967296',
      )).to eq(true)
      expect(compare_opts(
               'size=4t',
               'size=4398046511104',
      )).to eq(true)
    end
    it 'should treat sizes it does not understand as opaque' do
      expect(compare_opts(
               'size=4L',
               'size=4L',
      )).to eq(true)
      expect(compare_opts(
               'size=4L',
               'size=4',
      )).to eq(false)
      expect(compare_opts(
               'size=4L',
               'size=4T',
      )).to eq(false)
    end
    it 'should not normalize different values to be the same' do
      expect(compare_opts(
               'size=4K',
               'size=4000',
      )).to eq(false)
    end
  end

  context 'compare_fstype' do
    before(:each) do
      node.default['fb_fstab']['type_normalization_map'] = {}
    end
    it 'should see identical types as identical' do
      expect(compare_fstype('xfs', 'xfs')).to eq(true)
    end
    it 'should not see auto as the same as anything else' do
      expect(compare_fstype('xfs', 'auto')).to eq(false)
    end
    it 'should not see auto as the same as anything else - left' do
      expect(compare_fstype('auto', 'ext4')).to eq(false)
    end
    it 'should see different things as different' do
      expect(compare_fstype('xfs', 'ext4')).to eq(false)
    end
    it 'should normalize types according to the map' do
      node.default['fb_fstab']['type_normalization_map']['fuse.gluster'] =
        'gluster'
      compare_fstype('fuse.gluster', 'gluster')
    end
  end

  context 'should_keep' do
    mounted_sdc1 = {
      'device' => '/dev/sdc1',
      'mount' => '/mnt/foo',
      'fs_type' => 'xfs',
      'mount_options' => ['rw'],
    }
    basemounts_sdc1 = {
      '/dev/sdc1' => {
        'mount_point' => '/mnt/foo',
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      },
    }
    desired_sdc1 = {
      'extradrive' => {
        'device' => '/dev/sdc1',
        'type' => 'xfs',
        'opts' => 'rw',
        'mountpoint' => '/mnt/foo',
      },
    }

    it 'should keep identical desired fs' do
      expect(should_keep(
               mounted_sdc1,
               desired_sdc1,
               {},
      )).to eq(true)
    end
    it 'should keep identical base fs' do
      expect(should_keep(
               mounted_sdc1,
               {},
               basemounts_sdc1,
      )).to eq(true)
    end
    it 'should not keep random fs' do
      expect(should_keep(
               {
                 'device' => '/dev/sdd1',
                 'mount' => '/mnt/bar',
                 'fs_type' => 'xfs',
                 'mount_options' => ['rw'],
               },
               desired_sdc1,
               {},
      )).to eq(false)
    end
    it 'should keep desired devices mounted elsewhere' do
      expect(should_keep(
               {
                 'device' => '/dev/sdc1',
                 'mount' => '/mnt/bar',
                 'fs_type' => 'xfs',
                 'mount_options' => ['rw'],
               },
               desired_sdc1,
               {},
      )).to eq(true)
    end
    it 'should not keep base devices mounted elsewhere' do
      expect(should_keep(
               {
                 'device' => '/dev/sdc1',
                 'mount' => '/mnt/bar',
                 'fs_type' => 'xfs',
                 'mount_options' => ['rw'],
               },
               {},
               basemounts_sdc1,
      )).to eq(false)
    end
    it 'should keep autofs-parented mounts' do
      node.default[attr_name]['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      expect(should_keep(
               {
                 'device' => 'some.host:/dev/stupid',
                 'mount' => '/foo/bar',
                 'fs_type' => 'nfs',
               },
               {},
               {},
      )).to eq(true)
    end
    it 'should keep autofs-parented mounts - non NFS' do
      node.default[attr_name]['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      expect(should_keep(
               {
                 'device' => 'some.host:/dev/stupid',
                 'mount' => '/foo/bar',
                 'fs_type' => 'fuse',
               },
               {},
               {},
      )).to eq(true)
    end
    it 'should not keep non-autofs-parented NFS mounts' do
      node.default[attr_name]['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      expect(should_keep(
               {
                 'device' => 'some.host:/dev/stupid',
                 'mount' => '/thing/bar',
                 'fs_type' => 'fuse',
               },
               {},
               {},
      )).to eq(false)
    end
  end
  context 'tmpfs_mount_status' do
    before(:each) do
      node.default['fb_fstab']['ignorable_opts'] = []
      node.default['fb_fstab']['type_normalization_map'] = {}
      node.default['kernel'] = {
        'release' => '5.12.0-0_foo',
      }
      node.default['os'] = 'linux'
    end
    it 'should detect oldschool tmpfs as the same' do
      node.default[attr_name]['by_pair']['tmpfs,/mnt/waka'] = {
        'device' => 'tmpfs',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      node.default[attr_name]['by_mountpoint']['/mnt/waka'] = {
        'devices' => ['tmpfs'],
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=100M,rw',
        },
      }
      expect(Chef::Log).to receive(:warn).with(
        'fb_fstab: Treating ["tmpfs"] on /mnt/waka the same as awesomesauce ' +
        'on /mnt/waka because they are both tmpfs.',
      )
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:same)
    end
    it 'should detect identical filesystems as such' do
      node.default[attr_name]['by_pair']['awesomesauce,/mnt/waka'] = {
        'device' => 'awesomesauce',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=100M,rw',
        },
      }
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:same)
    end
    it 'should detect identical filesystems as such (Linux Kernel 5.9)' do
      node.default[attr_name]['by_pair']['awesomesauce,/mnt/waka'] = {
        'device' => 'awesomesauce',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw', 'inode64'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=100M,rw',
        },
      }
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:same)
    end
    it 'should detect remounts' do
      node.default[attr_name]['by_pair']['awesomesauce,/mnt/waka'] = {
        'device' => 'awesomesauce',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=200M,rw',
        },
      }
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:remount)
    end
    it 'should detect conflict' do
      node.default[attr_name]['by_pair']['/dev/sdc1,/mnt/waka'] = {
        'device' => '/dev/sdc1',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      node.default[attr_name]['by_mountpoint']['/mnt/waka'] = {
        'device' => '/dev/sdc1',
        'mount' => '/mnt/waka',
        'fs_type' => 'xfs',
        'mount_options' => ['defaults'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=200M,rw',
        },
      }
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:conflict)
    end
    it 'should detect missing fs' do
      node.default[attr_name] = {
        'by_pair' => {},
        'by_device' => {},
        'by_mountpoint' => {},
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => 'awesomesauce',
          'mount_point' => '/mnt/waka',
          'type' => 'tmpfs',
          'opts' => 'size=200M,rw',
        },
      }
      expect(tmpfs_mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:missing)
    end
  end
  context 'mount_status' do
    before(:each) do
      node.default['fb_fstab']['ignorable_opts'] = []
      node.default['fb_fstab']['type_normalization_map'] = {}
    end
    it 'should detect identical mounts as such' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:same)
    end
    it 'should detect identical mounts subvolumes' do
      node.default[attr_name]['by_device']['/dev/sdd1'] = {
        'device' => '/dev/sdd1',
        'mounts' => '/mnt/d0',
        'fs_type' => 'btrfs',
        'mount_options' => ['noatime', 'subvolid=123'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d1',
          'type' => 'btrfs',
          'opts' => 'subvolid=123',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:moved)
    end
    it 'should detect remount needed' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:remount)
    end
    it 'should detect moved filesystems - with different opts' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      }
      node.default[attr_name]['by_device']['/dev/sdd1'] = {
        'mounts' => ['/mnt/d0'],
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d1',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:moved)
    end
    it 'should detect handle auto as not an fstype conflict' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'auto',
        'mount_options' => ['rw', 'noatime'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'ext4',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:same)
    end
    it 'should detect fstype conflict - with different opts' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'ext4',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:conflict)
    end
    it 'should detect something-already-there conflict' do
      node.default[attr_name]['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      node.default[attr_name]['by_device']['/dev/sdd1'] = {
        'mounts' => ['/mnt/d0'],
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      node.default[attr_name]['by_mountpoint']['/mnt/d0'] = {
        'devices' => ['/dev/sdd1'],
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sde1',
          'mount_point' => '/mnt/d0',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:conflict)
    end
    it 'should detect missing filesystems' do
      node.default[attr_name]['by_pair']['/dev/sda1,/mnt/waka'] = {
        'device' => '/dev/sda1',
        'mount' => '/mnt/waka',
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:missing)
    end
    it 'should detect missing filesystems even if device is in ohai' do
      node.default[attr_name]['by_pair'] = {
        '/dev/sda1,/mnt/waka' => {
          'device' => '/dev/sda1',
          'mount' => '/mnt/waka',
          'fs_type' => 'xfs',
          'mount_options' => ['rw', 'noatime'],
        },
        # No 'mount' entry, it's not mounted
        '/dev/sdd1,' => {
          'device' => '/dev/sdd1',
          'fs_type' => 'xfs',
          'uuid' => '4e91b8f3-5fce-47a1-ba05-56f1cfa1acb7',
          'label' => '/mnt/d0',
        },
      }
      node.default[attr_name]['by_device'] = {
        '/dev/sda1' => {
          'mounts' => ['/mnt/waka'],
          'fs_type' => 'xfs',
          'mount_options' => ['rw', 'noatime'],
        },
        # No 'mount' entry, it's not mounted
        '/dev/sdd1' => {
          'mounts' => [],
          'fs_type' => 'xfs',
          'uuid' => '4e91b8f3-5fce-47a1-ba05-56f1cfa1acb7',
          'label' => '/mnt/d0',
        },
      }
      desired_mounts = {
        'awesomemount' => {
          'device' => '/dev/sdd1',
          'mount_point' => '/mnt/d0',
          'type' => 'xfs',
          'opts' => 'rw,noatime',
        },
      }
      expect(mount_status(
               desired_mounts['awesomemount'],
      )).to eq(:missing)
    end
  end
  context 'mount' do
    it 'should attempt to mount by mount_point' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
      }
      expect(node).to receive(:systemd?).and_return(false)
      expect(File).to receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out1')
      expect(so).to receive(:run_command).and_return(so)
      expect(so).to receive(:error?).and_return(false)
      expect(so).to receive(:error!).and_return(nil)
      expect(Mixlib::ShellOut).to receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      expect(mount(desired_mount, [], [])).to eq(true)
    end
    it 'should attempt to mount by systemd mount unit on systemd hosts' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
      }
      expect(node).to receive(:systemd?).and_return(true)
      expect(File).to receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out2')
      expect(so).to receive(:run_command).and_return(so)
      expect(so).to receive(:error!).and_return(nil)
      expect(so).to receive(:stdout).and_return('thisisaunit')
      so2 = double('FSshell_out1')
      expect(so2).to receive(:run_command).and_return(so2)
      expect(so2).to receive(:error?).and_return(false)
      expect(so2).to receive(:error!).and_return(nil)
      expect(Mixlib::ShellOut).to receive(:new).with(
        "/bin/systemd-escape -p --suffix=mount #{desired_mount['mount_point']}",
      ).and_return(so)

      expect(Mixlib::ShellOut).to receive(:new).with(
        '/bin/systemctl start thisisaunit',
      ).and_return(so2)
      expect(mount(desired_mount, [], [])).to eq(true)
    end
    it 'should raise failures on mount failure' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
      }
      expect(node).to receive(:systemd?).and_return(false)
      expect(File).to receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out2')
      expect(so).to receive(:run_command).and_return(so)
      expect(so).to receive(:error?).and_return(true)
      expect(so).to receive(:error!).
        and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect(Mixlib::ShellOut).to receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      expect do
        mount(desired_mount, [], [])
      end.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end
    it 'should not raise failures on mount failure, if failure allowed' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
        'allow_mount_failure' => true,
        'allow_remount_failure' => true,
      }
      expect(node).to receive(:systemd?).and_return(false)
      expect(File).to receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out3')
      expect(so).to receive(:run_command).and_return(so)
      expect(so).to receive(:error?).and_return(true)
      expect(Mixlib::ShellOut).to receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      expect(mount(desired_mount, [], [])).to eq(true)
    end
    it 'should not try to mount in-maintenance disks' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
        'mp_perms' => '0700',
        'mp_owner' => 'nobody',
        'mp_group' => 'nobody',
      }
      expect(mount(desired_mount, ['/dev/sdd1'], [])).to eq(true)
    end
    it 'should not try to mount in-maintenance mounts' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
        'mp_perms' => '0700',
        'mp_owner' => 'nobody',
        'mp_group' => 'nobody',
      }
      expect(mount(desired_mount, [], ['/mnt/d0'])).to eq(true)
    end
    it 'should create the mountpoint for you' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
        'mp_perms' => '0700',
        'mp_owner' => 'nobody',
        'mp_group' => 'nobody',
      }
      expect(node).to receive(:systemd?).and_return(false)
      expect(File).to receive(:exist?).with(desired_mount['mount_point']).
        and_return(false)
      expect(FileUtils).to receive(:mkdir_p).
        with(desired_mount['mount_point'],
             :mode => 0755).and_return(true)
      expect(FileUtils).to receive(:chmod).with(
        desired_mount['mp_perms'].to_i(8), desired_mount['mount_point']
      ).and_return(true)
      expect(FileUtils).to receive(:chown).with(
        desired_mount['mp_owner'], desired_mount['mp_group'],
        desired_mount['mount_point']
      ).and_return(true)
      so = double('FSshell_out4')
      expect(so).to receive(:run_command).and_return(so)
      expect(so).to receive(:error?).and_return(false)
      expect(so).to receive(:error!).and_return(nil)
      expect(Mixlib::ShellOut).to receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      expect(mount(desired_mount, [], [])).to eq(true)
    end
  end

  context 'check_unwanted_filesystems' do
    base_contents = <<EOF
    /dev/sda1 /                       ext4    defaults        1 1
    /dev/sda2 /boot                   ext3    defaults        1 2
    /dev/sda3 swap                    swap    defaults        0 0
EOF

    before(:each) do
      node.default['fb_fstab']['enable_unmount'] = true
      node.default['fb_fstab']['umount_ignores']['device_prefixes'] = []
      node.default['fb_fstab']['umount_ignores']['devices'] = []
      node.default['fb_fstab']['umount_ignores']['mount_point_prefixes'] = []
      node.default['fb_fstab']['umount_ignores']['mount_point_regexes'] = []
      node.default['fb_fstab']['umount_ignores']['mount_points'] = []
      node.default['fb_fstab']['umount_ignores']['types'] = []
      node.default['fb_fstab']['mounts'] = {}
      node.default[attr_name]['by_pair'] = {
        '/dev/sda1,/' => {
          'device' => '/dev/sda1',
          'mount' => '/',
          'fs_type' => 'ext4',
        },
        '/dev/sda2,/boot' => {
          'device' => '/dev/sda2',
          'mount' => '/boot',
          'fs_type' => 'ext3',
        },
        '/dev/sda3,' => {
          'device' => '/dev/sda3',
          'fs_type' => 'swap',
        },
        '/dev/sdb1,/foo' => {
          'device' => '/dev/sdb1',
          'mount' => '/foo',
          'fs_type' => 'xfs',
        },
      }
      node.default[attr_name]['by_device'] = {
        '/dev/sda1' => {
          'mounts' => ['/'],
          'fs_type' => 'ext4',
          'label' => '/',
        },
        '/dev/sda2' => {
          'mounts' => ['/boot'],
          'fs_type' => 'ext3',
          'label' => '/boot',
        },
        '/dev/sda3' => {
          'fs_type' => 'swap',
          'label' => '/swap',
        },
        '/dev/sdb1' => {
          'mounts' => ['/foo'],
          'fs_type' => 'xfs',
          'label' => '/foo',
        },
      }
      expect(File).to receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
    end

    it 'should unmount unknown mounts' do
      expect_any_instance_of(FB::FstabProvider).to receive(:converge_by).with('unmount /foo')
      check_unwanted_filesystems
    end

    it 'should not unmount ignored device prefixes' do
      node.default['fb_fstab']['umount_ignores']['device_prefixes'] = ['/dev/sdb']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end

    it 'should not unmount ignored devices' do
      node.default['fb_fstab']['umount_ignores']['devices'] = ['/dev/sdb1']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end

    it 'should not unmount ignored mount point prefixes' do
      node.default['fb_fstab']['umount_ignores']['mount_point_prefixes'] = ['/fo']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end

    it 'should not unmount ignored mount point regexes' do
      node.default['fb_fstab']['umount_ignores']['mount_point_regexes'] = ['^\/foo$']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end

    it 'should not unmount ignored mount points' do
      node.default['fb_fstab']['umount_ignores']['mount_points'] = ['/foo']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end

    it 'should not unmount ignored types' do
      node.default['fb_fstab']['umount_ignores']['types'] = ['xfs']
      expect_any_instance_of(FB::FstabProvider).not_to receive(:converge_by)
      check_unwanted_filesystems
    end
  end
end
