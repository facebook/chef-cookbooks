# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#

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
require_relative '../../fb_helpers/libraries/fb_helpers'

# rubocop:disable Style/MultilineBlockChain

recipe 'fb_users::default' do |tc|
  let(:node) { Chef::Node.new }

  let(:uid_map) do
    {
      'existing' => {
        'uid' => 42,
      },
      'new_basic' => {
        'uid' => 99,
        'system' => true,
        'comment' => 'fakeuser for testing',
      },
      'simple' => {
        'uid' => 88,
      },
      'complex' => {
        'uid' => 77,
        'system' => true,
        'comment' => 'look a testuser',
      },
      'cleanup' => {
        'uid' => 66,
      },
      'testuser' => {
        'uid' => 55,
      },
    }
  end

  let(:gid_map) do
    {
      'existing' => {
        'gid' => 4242,
      },
      'new_basic' => {
        'gid' => 9999,
        'system' => true,
      },
      'simple' => {
        'gid' => 8888,
      },
      'complex' => {
        'gid' => 7777,
      },
      'cleanup' => {
        'gid' => 6666,
      },
      'testgroup' => {
        'gid' => 5555,
      },
      'users' => {
        'gid' => 100,
        'system' => true,
      },
    }
  end

  let(:mock_db_item) { { 'password' => 'w000t' } }
  let(:mock_fb_users_db) { { 'complex' => mock_db_item } }

  before(:example) do
    stub_const('FB::Users::UID_MAP', uid_map)
    stub_const('FB::Users::GID_MAP', gid_map)
    stub_data_bag('fb_users_auth').and_return(mock_fb_users_db)
    stub_data_bag_item('fb_users_auth', 'complex').and_return(mock_db_item)
  end

  context 'with user_defaults' do
    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_users']) do |node|
        node.automatic['etc']['passwd']['existing']['uid'] = 42
        node.automatic['etc']['group']['existing']['gid'] = 4242
        node.automatic['filesystem']['by_mountpoint'] = {
          '/home' => {
            'fs_type' => 'nfs',
          },
          '/var/localhome' => {
            'fs_type' => 'foofs',
          },
        }
      end.converge('fb_users::test', described_recipe) do |node|
        node.default['fb_users'] = {
          'user_defaults' => {
            'gid' => 'existing',
            'manage_home' => false,
            'shell' => '/usr/fakebin',
          },
          'users' => {
            'existing' => {
              'gid' => 'existing',
              'shell' => '/bin/bash',
              'action' => :add,
            },
            'new_basic' => {
              'gid' => 'new_basic',
              'manage_home' => true,
              'action' => :add,
            },
            'simple' => {
              'action' => :add,
            },
            'complex' => {
              'gid' => 'complex',
              'shell' => '/bin/myshell',
              'home' => '/var/localhome/complex',
              'homedir_group' => 'users',
              'homedir_mode' => '0600',
              'manage_home' => true,
              'action' => :add,
            },
            'testuser' => {
              'gid' => 'testgroup',
              'home' => '/var/localhome/testuser',
              'homedir_group' => 'users',
              'manage_home' => false,
              'password' => 'myfakepassword',
              'shell' => '/bin/bash',
              'action' => :add,
              'notifies' => {
                'test notif' => {
                  'resource' => 'file[test resource]',
                  'action' => 'create',
                }
              },
            },
            'cleanup' => {
              'action' => :delete,
            },
          },
          'groups' => {
            'existing' => {
              'members' => [],
              'action' => :add,
            },
            'new_basic' => {
              'members' => [],
              'action' => :add,
            },
            'simple' => {
              'members' => [],
              'action' => :add,
            },
            'complex' => {
              'members' => ['testuser'],
              'action' => :add,
            },
            'testgroup' => {
              'members' => [],
              'action' => :add,
              'notifies' => {
                'test notif' => {
                  'resource' => 'file[test resource]',
                  'action' => 'delete',
                },
              },
            },
            'cleanup' => {
              'action' => :delete,
            },
          },
        }
      end
    end

    context 'manage user' do
      it 'creates the user with the values specified in UID_MAP' do
        expect(chef_run).to create_user('new_basic').with(
          :uid => 99,
          :gid => 9999,
          :home => '/home/new_basic',
          :manage_home => true,
          :shell => '/usr/fakebin',
          :system => true,
          :comment => 'fakeuser for testing',
        )
      end

      it 'uses the user_defaults if no values were passed to the api' do
        expect(chef_run).to create_user('simple').with(
          :uid => 88,
          :gid => 4242,
          :home => '/home/simple',
          :manage_home => false,
          :shell => '/usr/fakebin',
        )
      end

      it 'creates the user with the values provided to the api' do
        expect(chef_run).to create_user('testuser').with(
          :uid => 55,
          :gid => 5555,
          :shell => '/bin/bash',
          :home => '/var/localhome/testuser',
          :manage_home => false,
          :password => 'myfakepassword',
        )
      end

      it 'uses the password from the databag if it exists' do
        expect(chef_run).to create_user('complex').with(
          :uid => 77,
          :gid => 7777,
          :shell => '/bin/myshell',
          :home => '/var/localhome/complex',
          :manage_home => true,
          :password => 'w000t',
          :comment => 'look a testuser',
        )
      end

      it 'uses the homedir defaults if no values were passed to the api' do
        expect(chef_run).not_to create_directory('/home/existing')
      end

      it 'manages the users homedir' do
        expect(chef_run).to create_directory('/home/new_basic').with(
          :owner => 99,
          :group => 9999,
        )
      end

      it 'manages the homedir with the homedir options passed to the api' do
        expect(chef_run).to create_directory('/var/localhome/complex').with(
          :owner => 77,
          :group => 100,
          :mode => '0600',
        )
      end

      it 'does not manage homedir if manage_home is false' do
        expect(chef_run).not_to create_directory('/var/localhome/testuser')
      end

      # no need to test that the homedir is cleaned up, since the chef
      # user resource :delete action handles this for us if manage_home is true
      it 'deletes the user' do
        expect(chef_run).to remove_user('cleanup')
      end

      it 'notifies expected things' do
        expect(chef_run.user('testuser')).to notify('file[test resource]').
          to(:create)
      end
    end

    context 'manage group' do
      it 'bootstraps missing groups' do
        expect(chef_run).to create_group('bootstrap new_basic').with(
          :group_name => 'new_basic',
          :gid => 9999,
        )
      end

      it 'does not bootstrap groups that exist on system' do
        expect(chef_run).not_to create_group('bootstrap existing')
      end

      it 'does not bootstrap groups that will be deleted' do
        expect(chef_run).not_to create_group('bootstrap cleanup')
      end

      it 'creates the group with the values specified in GID_MAP' do
        expect(chef_run).to create_group('new_basic').with(
          :gid => 9999,
          :system => true,
          :members => [],
          :append => false,
        )
      end

      it 'creates the group with the values provided to the api' do
        expect(chef_run).to create_group('simple').with(
          :gid => 8888,
          :members => [],
          :append => false,
        )
        expect(chef_run).to create_group('complex').with(
          :gid => 7777,
          :members => ['testuser'],
          :append => false,
        )
      end

      it 'deletes the group' do
        expect(chef_run).to remove_group('cleanup')
      end

      it 'notifies expected things' do
        expect(chef_run.group('testgroup')).to notify('file[test resource]').
          to(:delete)
      end
    end
  end

  context 'with no user_defaults' do
    cached(:chef_run) do
      tc.chef_run(:step_into => ['fb_users']) do |node|
        node.automatic['etc']['passwd']['existing']['uid'] = 42
        node.automatic['etc']['group']['existing']['gid'] = 4242
        node.automatic['filesystem']['by_mountpoint'] = {
          '/home' => {
            'fs_type' => 'nfs',
          },
          '/var/localhome' => {
            'fs_type' => 'foofs',
          },
        }
      end.converge(described_recipe) do |node|
        node.default['fb_users']['users'] = {
          'existing' => {
            'gid' => 'existing',
            'home' => '/var/localhome/existing',
            'action' => :add,
          },
          'new_basic' => {
            'action' => :add,
          },
          'simple' => {
            'gid' => 'testgroup',
            'home' => '/var/localhome/simple',
            'manage_home' => true,
            'action' => :add,
          },
          'testuser' => {
            'gid' => 'testgroup',
            'home' => '/home/testuser',
            'manage_home' => false,
            'action' => :add,
          },
        }
        node.default['fb_users']['groups'] = {
          'existing' => {
            'members' => [],
            'action' => :add,
          },
        }
      end
    end

    context 'when manage_home is explicitly set' do
      it 'honors if manage_home is explicitly true' do
        expect(chef_run).to create_user('simple').with(
          :uid => 88,
          :gid => 5555,
          :home => '/var/localhome/simple',
          :manage_home => true,
          :shell => '/bin/bash',
        )
      end

      it 'honors if manage_home is explicitly false' do
        expect(chef_run).to create_user('testuser').with(
          :uid => 55,
          :gid => 5555,
          :home => '/home/testuser',
          :manage_home => false,
          :shell => '/bin/bash',
        )
      end
    end

    context 'manage_home not explicitly set' do
      it 'sets manage_home false for nfs/autofs mounts' do
        expect(chef_run).to create_user('new_basic').with(
          :uid => 99,
          :gid => 100,
          :home => '/home/new_basic',
          :manage_home => false,
          :shell => '/bin/bash',
          :system => true,
          :comment => 'fakeuser for testing',
        )
      end

      it 'sets manage_home true for all other fstypes' do
        expect(chef_run).to create_user('existing').with(
          :uid => 42,
          :gid => 4242,
          :home => '/var/localhome/existing',
          :manage_home => true,
          :shell => '/bin/bash',
        )
      end
    end
  end
end
# rubocop:enable Style/MultilineBlockChain
