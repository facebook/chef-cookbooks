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
require 'yaml'
require 'bookworm/configuration'

describe Bookworm::Configuration do
  before do
    # Mock all file system access
    allow_any_instance_of(described_class).to receive(:load).and_raise(LoadError)
    allow(YAML).to receive(:load_file).and_raise(StandardError)
  end

  describe '#initialize' do
    it 'initializes with empty source_dirs when no config found' do
      config = described_class.new
      expect(config.source_dirs).to eq([])
    end

    it 'sets system_contrib_dir to default' do
      config = described_class.new
      expect(config.system_contrib_dir).to eq(described_class::SYSTEM_CONTRIB_DIR)
    end
  end

  describe 'YAML configuration' do
    it 'loads source_dirs from YAML config' do
      allow(YAML).to receive(:load_file).and_return({
                                                      'source_dirs' => ['/custom/cookbooks'],
                                                    })

      config = described_class.new
      expect(config.source_dirs).to eq(['/custom/cookbooks'])
    end

    it 'loads debug from YAML config' do
      allow(YAML).to receive(:load_file).and_return({
                                                      'debug' => true,
                                                    })

      config = described_class.new
      expect(config.debug).to eq(true)
    end

    it 'loads system_contrib_dir from YAML config' do
      allow(YAML).to receive(:load_file).and_return({
                                                      'system_contrib_dir' => '/custom/contrib',
                                                    })

      config = described_class.new
      expect(config.system_contrib_dir).to eq('/custom/contrib')
    end
  end

  describe 'constants' do
    it 'defines SYSTEM_CONFIGURATION_RUBY_FILE' do
      expect(described_class::SYSTEM_CONFIGURATION_RUBY_FILE).to eq(
        '/usr/local/etc/bookworm/configuration.rb',
      )
    end

    it 'defines SYSTEM_CONTRIB_DIR' do
      expect(described_class::SYSTEM_CONTRIB_DIR).to eq(
        '/usr/local/etc/bookworm/contrib',
      )
    end
  end

  describe 'default constants override' do
    before do
      # Temporarily define the default constants
      stub_const('Bookworm::Configuration::DEFAULT_SOURCE_DIRS', ['/default/cookbooks'])
      stub_const('Bookworm::Configuration::DEFAULT_DEBUG', true)
    end

    it 'uses DEFAULT_SOURCE_DIRS when defined' do
      config = described_class.new
      expect(config.source_dirs).to eq(['/default/cookbooks'])
    end

    it 'uses DEFAULT_DEBUG when defined' do
      config = described_class.new
      expect(config.debug).to eq(true)
    end

    it 'allows YAML to override defaults' do
      allow(YAML).to receive(:load_file).and_return({
                                                      'source_dirs' => ['/yaml/cookbooks'],
                                                    })

      config = described_class.new
      expect(config.source_dirs).to eq(['/yaml/cookbooks'])
    end
  end
end
