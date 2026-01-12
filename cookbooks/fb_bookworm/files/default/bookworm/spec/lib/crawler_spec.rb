# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates
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
require_relative '../spec_helper'
require 'bookworm/keys'
require 'bookworm/crawler'

describe Bookworm::Crawler do
  let(:mock_config) do
    config = double('Configuration')
    allow(config).to receive(:source_dirs).and_return({
                                                        'cookbook_dirs' => ['/fake/cookbooks'],
                                                        'role_dirs' => ['/fake/roles'],
                                                      })
    config
  end

  describe '#initialize' do
    it 'initializes with empty processed_files when no keys given' do
      crawler = described_class.new(mock_config, :keys => [])
      expect(crawler.processed_files).to eq({})
    end

    it 'processes files for given keys' do
      allow(Dir).to receive(:glob).with('/fake/cookbooks/*/recipes/*.rb').and_return(
        ['/fake/cookbooks/mycookbook/recipes/default.rb'],
      )
      allow(File).to receive(:read).with('/fake/cookbooks/mycookbook/recipes/default.rb').and_return(
        "include_recipe 'foo'",
      )

      crawler = described_class.new(mock_config, :keys => ['recipe'])

      expect(crawler.processed_files).to have_key('recipe')
      recipe_path = '/fake/cookbooks/mycookbook/recipes/default.rb'
      expect(crawler.processed_files['recipe']).to have_key(recipe_path)
      expect(crawler.processed_files['recipe'][recipe_path]).to be_a(RuboCop::AST::Node)
    end
  end

  describe 'processing multiple keys' do
    it 'processes each key independently' do
      allow(Dir).to receive(:glob).with('/fake/cookbooks/*/recipes/*.rb').and_return(
        ['/fake/cookbooks/cookbook_a/recipes/default.rb'],
      )
      allow(Dir).to receive(:glob).with('/fake/cookbooks/*/attributes/*.rb').and_return(
        ['/fake/cookbooks/cookbook_a/attributes/default.rb'],
      )
      recipe_path = '/fake/cookbooks/cookbook_a/recipes/default.rb'
      attr_path = '/fake/cookbooks/cookbook_a/attributes/default.rb'
      allow(File).to receive(:read).with(recipe_path).and_return('recipe_code')
      allow(File).to receive(:read).with(attr_path).and_return('attribute_code')

      crawler = described_class.new(mock_config, :keys => ['recipe', 'attribute'])

      expect(crawler.processed_files.keys).to match_array(['recipe', 'attribute'])
    end
  end

  describe 'role processing' do
    it 'uses role_dirs for roles' do
      allow(Dir).to receive(:glob).with('/fake/roles/*.rb').and_return(
        ['/fake/roles/webserver.rb'],
      )
      allow(File).to receive(:read).with('/fake/roles/webserver.rb').and_return(
        "name 'webserver'",
      )

      crawler = described_class.new(mock_config, :keys => ['role'])

      expect(crawler.processed_files['role']).to have_key('/fake/roles/webserver.rb')
    end
  end

  describe 'JSON file processing' do
    it 'parses JSON files with JSON parser' do
      allow(Dir).to receive(:glob).with('/fake/cookbooks/*/recipes/*.json').and_return(
        ['/fake/cookbooks/mycookbook/recipes/data.json'],
      )
      allow(File).to receive(:read).with('/fake/cookbooks/mycookbook/recipes/data.json').and_return(
        '{"key": "value"}',
      )

      crawler = described_class.new(mock_config, :keys => ['recipejson'])

      json_path = '/fake/cookbooks/mycookbook/recipes/data.json'
      expect(crawler.processed_files['recipejson'][json_path]).to eq({ 'key' => 'value' })
    end
  end

  describe 'multiple source directories' do
    it 'collects files from all source directories' do
      config = double('Configuration')
      allow(config).to receive(:source_dirs).and_return({
                                                          'cookbook_dirs' => ['/cookbooks1', '/cookbooks2'],
                                                        })
      allow(Dir).to receive(:glob).with('/cookbooks1/*/recipes/*.rb').and_return(
        ['/cookbooks1/a/recipes/default.rb'],
      )
      allow(Dir).to receive(:glob).with('/cookbooks2/*/recipes/*.rb').and_return(
        ['/cookbooks2/b/recipes/default.rb'],
      )
      allow(File).to receive(:read).and_return('code')

      crawler = described_class.new(config, :keys => ['recipe'])

      expect(crawler.processed_files['recipe'].keys).to match_array([
        '/cookbooks1/a/recipes/default.rb',
        '/cookbooks2/b/recipes/default.rb',
      ])
    end
  end
end
