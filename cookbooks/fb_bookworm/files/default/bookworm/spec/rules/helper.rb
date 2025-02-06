# rubocop:disable Chef/Meta/SpecFilename
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
require 'pathname'
require 'bookworm/crawler'
require 'bookworm/exceptions'
require 'bookworm/infer_engine'

# Load all rule files
files = Dir.glob("#{__dir__}/../../lib/bookworm/rules/*.rb")
files.each do |f|
  name = Pathname(f).basename.to_s.gsub('.rb', '')
  ::Bookworm.load_rule_class name, :dir => "#{__dir__}/../../lib/bookworm/rules"
end

require_relative '../spec_helper'

def generate_ast(str)
  ::RuboCop::ProcessedSource.new(str, RUBY_VERSION.to_f)&.ast ||
    ::Bookworm::Crawler::EMPTY_RUBOCOP_AST
end
