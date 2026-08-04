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
require_relative '../../fb_helpers/libraries/fb_helpers'

# fb_users_user / fb_users_group are compile-time shims: they populate
# node['fb_users']['users'|'groups'][<name>] in after_created. We exercise that
# directly by building the resource in a run context and firing after_created,
# which avoids shipping a test-only recipe (mirrors how fb_sysfs unit-tests its
# resource logic directly).
module FBUsersResourceHelper
  def build_resource(type, name, &block)
    resource = Chef::Resource.resource_for_node(type, chef_run.node).
               new(name, chef_run.run_context)
    resource.instance_exec(&block) if block
    resource.after_created
    resource
  end
end

recipe 'fb_users::default' do |tc|
  include FBUsersResourceHelper

  let(:chef_run) do
    tc.chef_run.converge(described_recipe)
  end

  context 'fb_users_user' do
    it 'writes the user into the fb_users attribute' do
      build_resource(:fb_users_user, 'john') do
        gid 'users'
        shell '/bin/zsh'
      end
      expect(chef_run.node['fb_users']['users']['john'].to_h).to eq(
        'gid' => 'users',
        'shell' => '/bin/zsh',
        'action' => :add,
      )
    end

    it 'passes through every supported property' do
      build_resource(:fb_users_user, 'ada') do
        gid 'users'
        home '/var/localhome/ada'
        homedir_group 'users'
        homedir_mode '0700'
        manage_home true
        password 'hashedpw'
        shell '/bin/bash'
      end
      expect(chef_run.node['fb_users']['users']['ada'].to_h).to eq(
        'gid' => 'users',
        'home' => '/var/localhome/ada',
        'homedir_group' => 'users',
        'homedir_mode' => '0700',
        'manage_home' => true,
        'password' => 'hashedpw',
        'shell' => '/bin/bash',
        'action' => :add,
      )
    end

    it 'records only the action for a delete' do
      build_resource(:fb_users_user, 'olduser') do
        action :delete
      end
      expect(chef_run.node['fb_users']['users']['olduser'].to_h).to eq(
        'action' => :delete,
      )
    end
  end

  context 'fb_users_group' do
    it 'writes the group into the fb_users attribute' do
      build_resource(:fb_users_group, 'admins') do
        members ['john']
      end
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['john'],
        'action' => :add,
      )
    end

    it 'records only the action for a delete' do
      build_resource(:fb_users_group, 'oldgroup') do
        action :delete
      end
      expect(chef_run.node['fb_users']['groups']['oldgroup'].to_h).to eq(
        'action' => :delete,
      )
    end

    it 'preserves existing members when the resource omits members' do
      chef_run.node.default['fb_users']['groups']['admins'] = {
        'members' => ['john'],
        'action' => :add,
      }
      build_resource(:fb_users_group, 'admins')
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['john'],
        'action' => :add,
      )
    end

    it 'overwrites existing members when the resource sets them' do
      chef_run.node.default['fb_users']['groups']['admins'] = {
        'members' => ['john'],
        'action' => :add,
      }
      build_resource(:fb_users_group, 'admins') do
        members ['ada']
      end
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['ada'],
        'action' => :add,
      )
    end

    # Writing key-at-a-time means a :delete declared through the resource
    # inherits whatever the attribute API already put on the entry. Validation
    # has to tolerate the keys the converge path consumes on removal, or the
    # whyrun_safe_ruby_block in the recipe aborts the whole run.
    it 'does not trip validation when a delete inherits notifies' do
      stub_const('FB::Users::UID_MAP', {})
      stub_const('FB::Users::GID_MAP', { 'users' => { 'gid' => 100 } })
      chef_run.node.default['fb_users']['groups']['admins'] = {
        'members' => [],
        'action' => :add,
        'notifies' => {
          'restart foo' => {
            'resource' => 'service[foo]',
            'action' => 'restart',
          },
        },
      }
      build_resource(:fb_users_group, 'admins') do
        action :delete
      end
      entry = chef_run.node['fb_users']['groups']['admins']
      expect(entry['action']).to eq(:delete)
      expect(entry['notifies']['restart foo']['resource']).to eq('service[foo]')
      expect { FB::Users._validate(chef_run.node) }.not_to raise_error
    end

    it 'preserves members seeded by initialize_group' do
      FB::Users.initialize_group(chef_run.node, 'admins')
      build_resource(:fb_users_group, 'admins') do
        members ['ada']
      end
      build_resource(:fb_users_group, 'admins')
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['ada'],
        'action' => :add,
      )
    end
  end

  # Deletion is a *state*, not an event: only the final attribute value is
  # converged, so a later :add cancels an earlier :delete outright and the
  # group is never removed. That makes whatever the deleting recipe leaves in
  # `members` the membership the re-adding recipe inherits.
  context 'fb_users_group deleted and re-added' do
    it 'keeps membership when the delete omits members' do
      build_resource(:fb_users_group, 'admins') do
        members ['john']
      end
      build_resource(:fb_users_group, 'admins') do
        action :delete
      end
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['john'],
        'action' => :delete,
      )

      build_resource(:fb_users_group, 'admins') do
        action :add
      end
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => ['john'],
        'action' => :add,
      )
    end

    it 'clears membership when the delete passes an empty members' do
      build_resource(:fb_users_group, 'admins') do
        members ['john']
      end
      build_resource(:fb_users_group, 'admins') do
        members []
        action :delete
      end
      build_resource(:fb_users_group, 'admins') do
        action :add
      end
      expect(chef_run.node['fb_users']['groups']['admins'].to_h).to eq(
        'members' => [],
        'action' => :add,
      )
    end
  end
end
