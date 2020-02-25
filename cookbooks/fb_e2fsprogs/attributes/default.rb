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
#

ext4_features = %w{
  has_journal
  extent
  huge_file
  flex_bg
  64bit
  dir_nlink
  extra_isize
}

unless node.centos7?
  ext4_features << 'metadata_csum'
end

default['fb_e2fsprogs'] = {
  'manage_packages' => true,
  'e2fsck' => {
    'options' => {
      # Prevent e2fsck from stopping boot just because the clock is wrong
      'broken_system_clock' => false,
    },
  },
  'mke2fs' => {
    'defaults' => {
      'base_features' => %w{
        sparse_super
        large_file
        filetype
        resize_inode
        dir_index
        ext_attr
      },
      'default_mntopts' => %w{
        acl
        user_xattr
      },
      'enable_periodic_fsck' => false,
      'blocksize' => 4096,
      'inode_size' => 256,
      'inode_ratio' => 16384,
    },
    'fs_types' => {
      'ext3' => {
        'features' => %w{has_journal},
      },
      'ext4' => {
        'features' => ext4_features,
        'inode_size' => 256,
      },
      'small' => {
        'blocksize' => 1024,
        'inode_size' => 128,
        'inode_ratio' => 4096,
      },
      'floppy' => {
        'blocksize' => 1024,
        'inode_size' => 128,
        'inode_ratio' => 8192,
      },
      'big' => {
        'inode_ratio' => 32768,
      },
      'huge' => {
        'inode_ratio' => 65536,
      },
      'news' => {
        'inode_ratio' => 4096,
      },
      'largefile' => {
        'inode_ratio' => 1048576,
        'blocksize' => -1,
      },
      'largefile4' => {
        'inode_ratio' => 4194304,
        'blocksize' => -1,
      },
      'hurd' => {
        'blocksize' => 4096,
        'inode_size' => 128,
      },
    },
  },
}
