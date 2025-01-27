# Copyright (c) 2022-present, Meta Platforms, Inc. and affiliates
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
module Bookworm
  class Configuration
    attr :source_dirs, :debug
    attr_reader :system_contrib_dir

    # Allow for programmatic configuration override
    SYSTEM_CONFIGURATION_RUBY_FILE = '/usr/local/etc/bookworm/configuration.rb'.freeze
    SYSTEM_CONTRIB_DIR = '/usr/local/etc/bookworm/contrib'.freeze

    def initialize
      begin
        load SYSTEM_CONFIGURATION_RUBY_FILE
      rescue LoadError
        # puts "No configuration found at #{SYSTEM_CONFIGURATION_RUBY_FILE}"
        config = {}
      end
      begin
        config = YAML.load_file "#{Dir.home}/.bookworm.yml"
      rescue StandardError
        config = {}
      end

      @system_contrib_dir = SYSTEM_CONTRIB_DIR
      if Bookworm::Configuration.const_defined?(:DEFAULT_SOURCE_DIRS)
        @source_dirs ||= DEFAULT_SOURCE_DIRS
      end
      if Bookworm::Configuration.const_defined?(:DEFAULT_DEBUG)
        @debug ||= DEFAULT_DEBUG
      end

      @system_contrib_dir = config['system_contrib_dir'] if config['system_contrib_dir']
      @source_dirs = config['source_dirs'] if config['source_dirs']
      @debug = config['debug'] if config['debug']

      @source_dirs ||= []
    end
  end
end
