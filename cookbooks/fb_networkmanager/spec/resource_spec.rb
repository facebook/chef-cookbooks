#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
# Copyright (c) 2020-present, Facebook, Inc.
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
require_relative '../libraries/resource'

describe FB::Networkmanager::Resource do
  include FB::Networkmanager::Resource
  context '#conf_path' do
    it 'does not normalize when normalize is false' do
      expect(File.basename(conf_path('s  & SDFSDF', false))).
        to eq('s  & SDFSDF')
    end

    it 'does normalize when normalize is true' do
      expect(File.basename(conf_path('s  & SDFSDF', true))).
        to eq('fb_networkmanager_s__&_sdfsdf')
    end
  end

  context '#determine_files' do
    let(:cfile) do
      '/etc/NetworkManager/system-connections/fb_networkmanager_new'
    end

    let(:mfile) do
      '/etc/NetworkManager/system-connections/Old'
    end

    it 'uses migration file as source if it exists but the target does not' do
      expect(File).to receive(:exist?).with(cfile).and_return(false)
      expect(File).to receive(:exist?).with(mfile).and_return(true)
      expect(determine_files('new', { '_migrate_from' => 'Old' })).
        to eq({ 'config' => cfile, 'migrate' => mfile, 'from' => mfile })
    end

    it 'uses the target file as source if it exists even ' +
        'if the migration file exists' do
      expect(File).to receive(:exist?).with(cfile).and_return(true)
      allow(File).to receive(:exist?).with(mfile).and_return(true)
      expect(determine_files('new', { '_migrate_from' => 'Old' })).
        to eq({ 'config' => cfile, 'migrate' => mfile, 'from' => cfile })
    end

    it 'uses the target as source if only it exists' do
      expect(File).to receive(:exist?).with(cfile).and_return(true)
      allow(File).to receive(:exist?).with(mfile).and_return(false)
      expect(determine_files('new', { '_migrate_from' => 'Old' })).
        to eq({ 'config' => cfile, 'migrate' => mfile, 'from' => cfile })
    end

    it 'uses the target as source if no files exist, but warns' do
      expect(File).to receive(:exist?).with(cfile).and_return(false)
      allow(File).to receive(:exist?).with(mfile).and_return(false)
      expect(Chef::Log).to receive(:warn)
      expect(determine_files('new', { '_migrate_from' => 'Old' })).
        to eq({ 'config' => cfile, 'migrate' => mfile, 'from' => cfile })
    end

    it 'sets source to target if no migration requested; migrate is nil' do
      allow(File).to receive(:exist?).with(cfile).and_return(true)
      allow(File).to receive(:exist?).with(mfile).and_return(true)
      expect(determine_files('new', { 'id' => 'new' })).
        to eq({ 'config' => cfile, 'migrate' => nil, 'from' => cfile })
    end

    it 'uses removes _migrate_from key always' do
      allow(File).to receive(:exist?).with(cfile).and_return(true)
      allow(File).to receive(:exist?).with(mfile).and_return(true)
      info = { '_migrate_from' => 'Old', 'id' => 'new' }
      determine_files('new', info)
      expect(info).to eq({ 'id' => 'new' })
    end
  end

  context '#allowed_connections' do
    let(:node) { Chef::Node.new }
    it 'retuns requested connections, normalized' do
      node.default['fb_networkmanager']['system_connections'] = {
        'test1' => {},
        'test2' => {},
      }
      expect(allowed_connections(node)).to eq(
        ['fb_networkmanager_test1', 'fb_networkmanager_test2'],
      )
    end
  end

  context '#generate_config_hashes' do
    let(:from) do
      'afile'
    end

    let(:config) do
      {
        'section1' => {
          'optionA' => 'first_value',
        },
        'section2' => {
          'optionB' => 'second_value',
        },
      }
    end

    let(:config_with_default) do
      {
        '_defaults' => {
          'section1' => {
            'optionC' => 'default_value',
          },
        },
        'section1' => {
          'optionA' => 'first_value',
        },
        'section2' => {
          'optionB' => 'second_value',
        },
      }
    end

    let(:from_contents) do
      <<~EOS
      [oldsection]
      key=value

      [section1]
      existing=stuff
      optionA=previous_value

      [section2]
      blue=red
      EOS
    end

    let(:from_contents_with_default_override) do
      <<~EOS
      [oldsection]
      key=value

      [section1]
      existing=stuff
      optionA=previous_value
      optionC=user_value

      [section2]
      blue=red
      EOS
    end

    let(:from_hash) do
      {
        'oldsection' => {
          'key' => 'value',
        },
        'section1' => {
          'existing' => 'stuff',
          'optionA' => 'previous_value',
        },
        'section2' => {
          'blue' => 'red',
        },
      }
    end

    let(:from_hash_with_default_override) do
      {
        'oldsection' => {
          'key' => 'value',
        },
        'section1' => {
          'existing' => 'stuff',
          'optionA' => 'previous_value',
          'optionC' => 'user_value',
        },
        'section2' => {
          'blue' => 'red',
        },
      }
    end

    it 'returns the desired config with no source file' do
      expect(File).to receive(:exist?).with(from).and_return(false)
      expect(generate_config_hashes(from, config)).to eq([{}, config])
    end

    it 'lets new data wins when a source file exists' do
      expect(File).to receive(:exist?).with(from).and_return(true)
      expect(File).to receive(:read).with(from).and_return(from_contents)
      expected = {
        # no conflict, comes from old file
        'oldsection' => {
          'key' => 'value',
        },
        'section1' => {
          # no conflict, from old file
          'existing' => 'stuff',
          # conflict, new data wins
          'optionA' => 'first_value',
        },
        'section2' => {
          # no conflict, old file
          'blue' => 'red',
          # new data
          'optionB' => 'second_value',
        },
      }
      expect(generate_config_hashes(from, config)).to eq([from_hash, expected])
    end

    it 'includes defaults that are not overwritten' do
      expect(File).to receive(:exist?).with(from).and_return(true)
      expect(File).to receive(:read).with(from).and_return(from_contents)
      expected = {
        # no conflict, comes from old file
        'oldsection' => {
          'key' => 'value',
        },
        'section1' => {
          # no conflict, from old file
          'existing' => 'stuff',
          # conflict, new data wins
          'optionA' => 'first_value',
          # default
          'optionC' => 'default_value',
        },
        'section2' => {
          # no conflict, old file
          'blue' => 'red',
          # new data
          'optionB' => 'second_value',
        },
      }
      expect(generate_config_hashes(from, config_with_default)).
        to eq([from_hash, expected])
    end

    it 'lets users overwrite default-only settings' do
      expect(File).to receive(:exist?).with(from).and_return(true)
      expect(File).to receive(:read).with(from).and_return(
        from_contents_with_default_override,
      )
      expected = {
        # no conflict, comes from old file
        'oldsection' => {
          'key' => 'value',
        },
        'section1' => {
          # no conflict, from old file
          'existing' => 'stuff',
          # conflict, new data wins
          'optionA' => 'first_value',
          # default only, user did overwrite, should have user value
          'optionC' => 'user_value',
        },
        'section2' => {
          # no conflict, old file
          'blue' => 'red',
          # new data
          'optionB' => 'second_value',
        },
      }
      expect(generate_config_hashes(from, config_with_default)).
        to eq([from_hash_with_default_override, expected])
    end
  end
end
