# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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

require_relative '../libraries/chef_hints_helpers.rb'
require_relative '../../fb_helpers/libraries/fb_helpers.rb'

require 'chef/node'

describe FB::ChefHints do
  context 'valid_hints?' do
    it 'returns false if source is missing' do
      hint = {
        'hint' => {
          'foo' => 1,
        },
      }
      expect(FB::ChefHints.valid_hints?(hint)).to eq(false)
    end

    it 'returns false if hint is missing' do
      expect(FB::ChefHints.valid_hints?({ 'source' => 'foo' })).
        to eq(false)
    end

    it 'returns false if source is not allowed' do
      hint = {
        'source' => 'foo',
        'hint' => {
          'foo' => 1,
        },
      }
      expect(FB::ChefHints.valid_hints?(hint)).to eq(false)
    end

    it 'returns true if source is allowed' do
      hint = {
        'source' => 'foo',
        'hint' => {
          'foo' => 1,
        },
      }
      expect(FB::ChefHints.valid_hints?(hint, ['foo'])).
        to eq(true)
    end
  end

  context 'apply_hints' do
    it 'skips a hint if source is not allowed' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = [].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => 0,
          },
        },
      }
      node = Chef::Node.new
      node.default['foo']['bar'] = 1
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq(1)
    end

    it 'skips a hint if hint is not allowed' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = [].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => 0,
          },
        },
      }
      node = Chef::Node.new
      node.default['foo']['bar'] = 1
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq(1)
    end

    it 'sets an allowed leaf Integer attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => 0,
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = 1
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq(0)
    end

    it 'sets an allowed leaf String attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => 'pie',
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = 'cake'
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq('pie')
    end

    it 'sets an allowed leaf Array attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => ['pie'],
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = ['cake']
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq(['pie'])
    end

    it 'sets an allowed leaf Hash attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => { 'pie' => 1 },
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = { 'cake' => 1 }
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq({ 'pie' => 1 })
    end

    it 'clears an allowed leaf Array attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => [],
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = ['cake']
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq([])
    end

    it 'clears an allowed leaf Hash attribute hint' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => {},
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar'] = { 'cake' => 1 }
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']).to eq({})
    end

    it 'leaves attributes unchanged if filter does not match' do
      FB::ChefHintsSiteData::ALLOWED_SOURCES = ['chefspec'].freeze
      FB::ChefHintsSiteData::ALLOWED_HINTS = ['foo/bar/cake'].freeze
      hint = {
        'source' => 'chefspec',
        'hint' => {
          'foo' => {
            'bar' => {
              'pie' => {
                'baz' => 1,
              },
            },
          },
        },
      }

      node = Chef::Node.new
      node.default['foo']['bar']['pie']['baz'] = 1
      allow(FB::Helpers).to receive(:parse_json_file).
        with('hint.json', Hash, true).and_return(hint)
      FB::ChefHints.apply_hint(node, 'hint.json')
      expect(node['foo']['bar']['pie']['baz']).to eq(1)
    end
  end
end
