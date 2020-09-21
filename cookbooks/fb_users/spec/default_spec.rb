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
require './spec/spec_helper'
require_relative '../libraries/default'

recipe 'fb_users::default' do |_tc|
  describe FB::Users do
    let(:node) { Chef::Node.new }
    context 'Validation' do
      before(:each) do
        node.default['fb_users'] = {
          'user_defaults' => {},
          'users' => {
            'testuser' => {
              'shell' => '/bin/zsh',
              'gid' => 'testgroup',
              'action' => :add,
            },
          },
          'groups' => {
            'testgroup' => {
              'members' => ['testuser'],
              'action' => :add,
            },
          },
        }
      end

      it 'should not fail if we did not specify protected ranges' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        expect { FB::Users._validate(node) }.not_to raise_error
      end

      it 'should not fail if we did not specify a protected uid range' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_GID_RANGES', { 'my gid' => [777] })
        expect { FB::Users._validate(node) }.not_to raise_error
      end

      it 'should not fail if we did not specify a protected gid range' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_UID_RANGES', { 'my uid' => [77] })
        expect { FB::Users._validate(node) }.not_to raise_error
      end

      it 'should not fail if nothing collides' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_UID_RANGES', { 'my uid' => [99..222] })
        stub_const('FB::Users::RESERVED_GID_RANGES', { 'my gid' => [45, 77] })
        expect { FB::Users._validate(node) }.not_to raise_error
      end

      it 'should fail if a protected uid array collides with a user' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_UID_RANGES', { 'my uid' => [42] })
        expect { FB::Users._validate(node) }.to raise_error(
          RuntimeError, /User testuser in UID map is in the reserved range/
        )
      end

      it 'should fail if a protected uid range collides with a user' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_UID_RANGES', { 'my uid' => 40..44 })
        expect { FB::Users._validate(node) }.to raise_error(
          RuntimeError, /User testuser in UID map is in the reserved range/
        )
      end

      it 'should fail if a protected gid array collides with a group' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_GID_RANGES', { 'my gid' => [23, 4242] })
        expect { FB::Users._validate(node) }.to raise_error(
          RuntimeError, /Group testgroup in GID map is in the reserved range/
        )
      end

      it 'should fail if a protected gid range collides with a group' do
        stub_const('FB::Users::UID_MAP', { 'testuser' => { 'uid' => 42 } })
        stub_const('FB::Users::GID_MAP', { 'testgroup' => { 'gid' => 4242 } })
        stub_const('FB::Users::RESERVED_GID_RANGES', { 'my gid' => 4240..4244 })
        expect { FB::Users._validate(node) }.to raise_error(
          RuntimeError, /Group testgroup in GID map is in the reserved range/
        )
      end
    end
  end
end
