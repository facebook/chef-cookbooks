# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require 'chef/node'
# we know relative_requires is bad, but it allows us to handle pathing
# differences between internal repo and github
require_relative '../libraries/default'
require_relative '../libraries/provider'

include FB::FstabProvider

describe 'FB::Fstab' do
  let(:node) { Chef::Node.new }
  # rubocop:disable LineLength
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
  # rubocop:enable LineLength

  context 'generate_base_fstab' do
    it 'should not regenerate base fstab' do
      File.should_receive(:exist?).with(FB::Fstab::BASE_FILENAME).
        and_return(true)
      File.should_receive(:size).with(FB::Fstab::BASE_FILENAME).
        and_return(12)
      File.should_not_receive(:open)
      FB::Fstab.generate_base_fstab
    end
    it 'should generate new base fstab' do
      File.should_receive(:exist?).with(FB::Fstab::BASE_FILENAME).
        and_return(false)
      FileUtils.should_receive(:cp).and_return(nil)
      FileUtils.should_receive(:chmod).and_return([
        '/root/fstab.before_fb_fstab',
      ])
      File.should_receive(:read).and_return(full_contents)
      File.should_receive(:write).with(FB::Fstab::BASE_FILENAME, base_contents)
      FB::Fstab.generate_base_fstab
    end
  end

  context 'determine_base_fstab_entries' do
    it 'should regenerate base fstab properly' do
      FB::Fstab.determine_base_fstab_entries(full_contents).
        should eq(base_contents)
    end
    it 'should not include exta tmpfs mounts' do
      FB::Fstab.determine_base_fstab_entries(full_contents).
        should eq(base_contents)
    end
  end

  context 'autofs_parent' do
    before(:each) do
      node.default['filesystem2']['by_pair']['foo:/bar/baz,/mnt/foo'] = {
        'device' => 'foo:/bar/baz',
        'mount' => '/mnt/foo',
        'fs_type' => 'autofs',
      }
    end
    it 'should return the autofs parent when one exists' do
      FB::Fstab.autofs_parent('/mnt/foo/bar', node).should eq('/mnt/foo')
    end
    it 'should return the autofs dir when same as mount' do
      FB::Fstab.autofs_parent('/mnt/foo', node).should eq('/mnt/foo')
    end
    it 'should return false if no conflict with autofs' do
      FB::Fstab.autofs_parent('/mnt/waka', node).should eq(false)
    end
  end
  context 'label_to_device' do
    it 'should find the right label' do
      node.default['filesystem2']['by_device'] = {
        'foo' => {
          'label' => 'label1',
        },
        'bar' => {
          'label' => 'label2',
        },
      }
      FB::Fstab.label_to_device('label2', node).should eq('bar')
    end
    it 'should not get confused by fs without label' do
      node.default['filesystem2']['by_device'] = {
        'foo' => {
          'uuid' => 'uuid1',
        },
        'bar' => {
          'label' => 'label2',
        },
      }
      FB::Fstab.label_to_device('label2', node).should eq('bar')
    end
    it 'should fail on missing label' do
      node.default['filesystem2']['by_device'] = {
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
      node.default['filesystem2']['by_device'] = {
        'foo' => {
          'uuid' => 'uuid1',
        },
        'bar' => {
          'uuid' => 'uuid2',
        },
      }
      FB::Fstab.uuid_to_device('uuid2', node).should eq('bar')
    end
    it 'should not get confused by fs without uuid' do
      node.default['filesystem2']['by_device'] = {
        'foo' => {
          'label' => 'label1',
        },
        'bar' => {
          'uuid' => 'uuid2',
        },
      }
      FB::Fstab.uuid_to_device('uuid2', node).should eq('bar')
    end
    it 'should fail on missing uuid' do
      node.default['filesystem2']['by_device'] = {
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
  context 'get_in_maint_disks' do
    it 'should return an empty array if file does not exist' do
      File.should_receive(:exist?).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(false)
      FB::Fstab.get_in_maint_disks.should eq([])
    end
    it 'should delete stale files' do
      stat = double('FSstat')
      stat.should_receive(:mtime).and_return(Time.new - 60 * 60 * 24 * 8)
      File.should_receive(:exist?).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(true)
      File.should_receive(:stat).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(stat)
      File.should_receive(:unlink).with(FB::Fstab::IN_MAINT_DISKS_FILENAME).
        and_return(true)
      FB::Fstab.get_in_maint_disks.should eq([])
    end
  end
end

describe 'FB::FstabProvider', :include_provider do
  # rubocop:disable LineLength
  base_contents = <<EOF
UUID=28137926-9c39-44c0-90d3-3b158fc97ff9 /                       ext4    defaults,discard 1 1
LABEL=/boot /boot                   ext3    defaults        1 2
UUID=2ace4f5f-c8c5-4d3a-a027-d12076bdab0c swap                    swap    defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs /dev/shm tmpfs defaults,size=4G 0 0
EOF
  # rubocop:enable LineLength
  let(:node) { Chef::Node.new }
  before do
    node.default['filesystem2'] = {
      'by_pair' => {},
      'by_device' => {},
      'by_mountpoint' => {},
    }
  end

  context 'compare_opts' do
    it 'should find identical things identical' do
      compare_opts('rw,size=1G', 'rw,size=1G').should eq(true)
    end
    it 'should find different-order strings identical' do
      compare_opts('size=1G,rw', 'rw,size=1G').should eq(true)
    end
    it 'should find arrays and strings identical' do
      compare_opts('rw,size=1G', ['size=1G', 'rw']).should eq(true)
    end
    it 'should treat missing-rw opts as identical' do
      compare_opts('size=1G', ['size=1G', 'rw']).should eq(true)
    end
    it 'should not treat ro and rw as the same' do
      compare_opts('size=1G,ro', ['size=1G', 'rw']).should eq(false)
    end
    it 'should handle arrays the same' do
      compare_opts(['size=1G'], ['size=1G', 'rw']).should eq(true)
    end
    it 'should catch different sizes as different opts' do
      compare_opts(['rw', 'size=2G'], ['size=1G', 'rw']).should eq(false)
    end
  end

  context 'compare_fstype' do
    it 'should see identical types as identical' do
      compare_fstype('xfs', 'xfs').should eq(true)
    end
    it 'should not see auto as identical to anything except itself' do
      compare_fstype('autofs', 'xfs').should eq(false)
    end
    it 'should not see different filesystems as the same' do
      compare_fstype('ext4', 'ext3').should eq(false)
    end
  end

  context 'fstype_sameish' do
    it 'should see identical types as identical' do
      fstype_sameish('xfs', 'xfs').should eq(true)
    end
    it 'should see auto as the same as anything' do
      fstype_sameish('xfs', 'auto').should eq(true)
    end
    it 'should see auto as the same as anything - left' do
      fstype_sameish('auto', 'ext4').should eq(true)
    end
    it 'should see different things as different' do
      fstype_sameish('xfs', 'ext4').should eq(false)
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
      should_keep(
        mounted_sdc1,
        desired_sdc1,
        {},
      ).should eq(true)
    end
    it 'should keep identical base fs' do
      should_keep(
        mounted_sdc1,
        {},
        basemounts_sdc1,
      ).should eq(true)
    end
    it 'should not keep random fs' do
      should_keep(
        {
          'device' => '/dev/sdd1',
          'mount' => '/mnt/bar',
          'fs_type' => 'xfs',
          'mount_options' => ['rw'],
        },
        desired_sdc1,
        {},
      ).should eq(false)
    end
    it 'should keep desired devices mounted elsewhere' do
      should_keep(
        {
          'device' => '/dev/sdc1',
          'mount' => '/mnt/bar',
          'fs_type' => 'xfs',
          'mount_options' => ['rw'],
        },
        desired_sdc1,
        {},
      ).should eq(true)
    end
    it 'should not keep base devices mounted elsewhere' do
      should_keep(
        {
          'device' => '/dev/sdc1',
          'mount' => '/mnt/bar',
          'fs_type' => 'xfs',
          'mount_options' => ['rw'],
        },
        {},
        basemounts_sdc1,
      ).should eq(false)
    end
    it 'should keep autofs-parented mounts' do
      node.default['filesystem2']['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      should_keep(
        {
          'device' => 'some.host:/dev/stupid',
          'mount' => '/foo/bar',
          'fs_type' => 'nfs',
        },
        {},
        {},
      ).should eq(true)
    end
    it 'should keep autofs-parented mounts - non NFS' do
      node.default['filesystem2']['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      should_keep(
        {
          'device' => 'some.host:/dev/stupid',
          'mount' => '/foo/bar',
          'fs_type' => 'fuse',
        },
        {},
        {},
      ).should eq(true)
    end
    it 'should not keep non-autofs-parented NFS mounts' do
      node.default['filesystem2']['by_pair']['auto.waka,/foo'] = {
        'device' => 'auto.waka',
        'mount' => '/foo',
        'fs_type' => 'autofs',
      }
      should_keep(
        {
          'device' => 'some.host:/dev/stupid',
          'mount' => '/thing/bar',
          'fs_type' => 'fuse',
        },
        {},
        {},
      ).should eq(false)
    end
  end
  context 'get_base_mounts' do
    it 'should parse base mounts correctly' do
      node.default['filesystem2']['by_device'] = {
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
      File.should_receive(:read).with(FB::Fstab::BASE_FILENAME).
        and_return(base_contents)
      m = get_base_mounts
      m.should eq(
        {
          '/dev/sda1' => {
            'mount_point' => '/',
            'type' => 'ext4',
            'opts' => 'defaults,discard',
          },
          '/dev/sda2' => {
            'mount_point' => '/boot',
            'type' => 'ext3',
            'opts' => 'defaults',
          },
          '/dev/sda3' => {
            'mount_point' => 'swap',
            'type' => 'swap',
            'opts' => 'defaults',
          },
          'devpts' => {
            'mount_point' => '/dev/pts',
            'type' => 'devpts',
            'opts' => 'gid=5,mode=620',
          },
          'sysfs' => {
            'mount_point' => '/sys',
            'type' => 'sysfs',
            'opts' => 'defaults',
          },
          'proc' => {
            'mount_point' => '/proc',
            'type' => 'proc',
            'opts' => 'defaults',
          },
          'tmpfs' => {
            'mount_point' => '/dev/shm',
            'type' => 'tmpfs',
            'opts' => 'defaults,size=4G',
          },
        },
      )
    end
  end
  context 'tmpfs_mount_status' do
    it 'should detect oldschool tmpfs as the same' do
      node.default['filesystem2']['by_pair']['tmpfs,/mnt/waka'] = {
        'device' => 'tmpfs',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      node.default['filesystem2']['by_mountpoint']['/mnt/waka'] = {
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
      Chef::Log.should_receive(:warn).with(
        'fb_fstab: Treating ["tmpfs"] on /mnt/waka the same as awesomesauce ' +
        'on /mnt/waka because they are both tmpfs.',
      )
      tmpfs_mount_status(desired_mounts['awesomemount']).should eq(:same)
    end
    it 'should detect identical filesystems as such' do
      node.default['filesystem2']['by_pair']['awesomesauce,/mnt/waka'] = {
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
      tmpfs_mount_status(desired_mounts['awesomemount']).should eq(:same)
    end
    it 'should detect remounts' do
      node.default['filesystem2']['by_pair']['awesomesauce,/mnt/waka'] = {
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
      tmpfs_mount_status(desired_mounts['awesomemount']).should eq(:remount)
    end
    it 'should detect conflict' do
      node.default['filesystem2']['by_pair']['/dev/sdc1,/mnt/waka'] = {
        'device' => '/dev/sdc1',
        'mount' => '/mnt/waka',
        'fs_type' => 'tmpfs',
        'mount_options' => ['size=100M', 'rw'],
      }
      node.default['filesystem2']['by_mountpoint']['/mnt/waka'] = {
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
      tmpfs_mount_status(desired_mounts['awesomemount']).should eq(:conflict)
    end
    it 'should detect missing fs' do
      node.default['filesystem2'] = {
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
      tmpfs_mount_status(desired_mounts['awesomemount']).should eq(:missing)
    end
  end
  context 'mount_status' do
    it 'should detect identical mounts as such' do
      node.default['filesystem2']['by_pair']['/dev/sdd1,/mnt/d0'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:same)
    end
    it 'should detect remount needed' do
      node.default['filesystem2']['by_pair']['/dev/sdd1,/mnt/d0'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:remount)
    end
    it 'should detect moved filesystems - with different opts' do
      node.default['filesystem2']['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw'],
      }
      node.default['filesystem2']['by_device']['/dev/sdd1'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:moved)
    end
    it 'should detect fstype conflict - with different opts' do
      node.default['filesystem2']['by_pair']['/dev/sdd1,/mnt/d0'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:conflict)
    end
    it 'should detect something-already-there conflict' do
      node.default['filesystem2']['by_pair']['/dev/sdd1,/mnt/d0'] = {
        'device' => '/dev/sdd1',
        'mount' => '/mnt/d0',
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      node.default['filesystem2']['by_device']['/dev/sdd1'] = {
        'mounts' => ['/mnt/d0'],
        'fs_type' => 'xfs',
        'mount_options' => ['rw', 'noatime'],
      }
      node.default['filesystem2']['by_mountpoint']['/mnt/d0'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:conflict)
    end
    it 'should detect missing filesystems' do
      node.default['filesystem2']['by_pair']['/dev/sda1,/mnt/waka'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:missing)
    end
    it 'should detect missing filesystems even if device is in ohai' do
      node.default['filesystem2']['by_pair'] = {
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
      node.default['filesystem2']['by_device'] = {
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
      mount_status(desired_mounts['awesomemount']).should eq(:missing)
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
      File.should_receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out1')
      so.should_receive(:run_command).and_return(so)
      so.should_receive(:error?).and_return(false)
      so.should_receive(:error!).and_return(nil)
      Mixlib::ShellOut.should_receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      mount(desired_mount, []).should eq(true)
    end
    it 'should raise failures on mount failure' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
      }
      File.should_receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out2')
      so.should_receive(:run_command).and_return(so)
      so.should_receive(:error?).and_return(true)
      so.should_receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      Mixlib::ShellOut.should_receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      expect do
        mount(desired_mount, [])
      end.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end
    it 'should not raise failures on mount failure, if failure allowed' do
      desired_mount = {
        'device' => '/dev/sdd1',
        'mount_point' => '/mnt/d0',
        'type' => 'xfs',
        'opts' => 'rw,noatime',
        'allow_mount_failure' => true,
      }
      File.should_receive(:exist?).with(desired_mount['mount_point']).
        and_return(true)
      so = double('FSshell_out3')
      so.should_receive(:run_command).and_return(so)
      so.should_receive(:error?).and_return(true)
      Mixlib::ShellOut.should_receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      mount(desired_mount, []).should eq(true)
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
      mount(desired_mount, ['/dev/sdd1']).should eq(true)
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
      File.should_receive(:exist?).with(desired_mount['mount_point']).
        and_return(false)
      FileUtils.should_receive(:mkdir_p).with(desired_mount['mount_point'],
                                              :mode => 0755).and_return(true)
      FileUtils.should_receive(:chmod).with(
        desired_mount['mp_perms'].to_i(8), desired_mount['mount_point']
      ).and_return(true)
      FileUtils.should_receive(:chown).with(
        desired_mount['mp_owner'], desired_mount['mp_group'],
        desired_mount['mount_point']
      ).and_return(true)
      so = double('FSshell_out4')
      so.should_receive(:run_command).and_return(so)
      so.should_receive(:error?).and_return(false)
      so.should_receive(:error!).and_return(nil)
      Mixlib::ShellOut.should_receive(:new).with(
        "cd /dev/shm && /bin/mount #{desired_mount['mount_point']}",
      ).and_return(so)
      mount(desired_mount, []).should eq(true)
    end
  end
end
