# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

require './spec/spec_helper'
require './scripts/chef/shard'
require_relative '../../fb_helpers/libraries/node_methods'
require_relative '../libraries/default'
require_relative './lsblk.rb'

describe 'fb_swap' do
  let(:node) { Chef::Node.new }

  before(:each) do
    node.default['fb_swap']['filesystem'] = '/'
    node.default['filesystem2']['by_mountpoint']['/'] = {
      'fs_type' => 'ext4',
      'devices' => ['/dev/blocka42'],
    }
  end

  context 'btrfs' do
    before do
      node.default['filesystem2']['by_mountpoint']['/']['fs_type'] = 'btrfs'
    end
    it 'should return false if btrfs' do
      FB::FbSwap.swap_file_possible?(node).should eq(false)
    end
  end

  context 'rotational' do
    before do
      mock_lsblk('1')
    end
    it 'should return false if rotational' do
      FB::FbSwap.swap_file_possible?(node).should eq(false)
    end
  end

  context 'default' do
    before do
      mock_lsblk('0')
    end
    it 'should return true if not btrfs, and not rotational' do
      FB::FbSwap.swap_file_possible?(node).should eq(true)
    end
  end
end
