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
  class Crawler
    attr_reader :processed_files

    def initialize(config, keys: [])
      @config = config
      @intake_queue = {}
      @processed_files = {}

      # TODO(dcrosby) add messages to verbose mode
      keys.each do |key|
        generate_file_queue(key)
        process_paths(key)
      end
    end

    private

    def generate_file_queue(key)
      v = BOOKWORM_KEYS[key]
      @intake_queue[key] = @config.source_dirs[v['source_dirs']].
                           map { |d| Dir.glob("#{d}/#{v['glob_pattern']}") }.flatten
    end

    def process_paths(key)
      queue = @intake_queue[key]
      processed_files = {}
      parser = BOOKWORM_KEYS[key]['parser']
      until queue.empty?
        path = queue.pop
        processed_files[path] = parser.parse(File.read(path))
      end
      @processed_files[key] = processed_files
    end
  end
end
