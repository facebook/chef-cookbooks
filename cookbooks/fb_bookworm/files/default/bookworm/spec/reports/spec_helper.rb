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

# rubocop:disable Chef/Meta/SpecFilename
require 'pathname'

require_relative '../spec_helper'

require 'bookworm/keys'
require 'bookworm/crawler'
require 'bookworm/exceptions'
require 'bookworm/infer_engine'
require 'bookworm/report_builder'

# Load all rule files (needed by some reports like NoParsedRuby)
# Guard against double-loading when running full spec suite
unless defined?(Bookworm::InferRules) && Bookworm::InferRules.constants.any?
  rules_dir = "#{__dir__}/../../lib/bookworm/rules/"
  files = Dir.glob("#{rules_dir}/*.rb")
  files.each do |f|
    name = Pathname(f).basename.to_s.gsub('.rb', '')
    ::Bookworm.load_rule_class name, :dir => rules_dir
  end
end

# Load all report files
# Guard against double-loading when running full spec suite
unless defined?(Bookworm::Reports) && Bookworm::Reports.constants.any?
  reports_dir = "#{__dir__}/../../lib/bookworm/reports/"
  files = Dir.glob("#{reports_dir}/*.rb")
  files.each do |f|
    name = Pathname(f).basename.to_s.gsub('.rb', '')
    ::Bookworm.load_report_class name, :dir => reports_dir
  end
end

# Mock KnowledgeBase for testing reports
class MockKnowledgeBase
  attr_accessor :recipes, :recipejsons, :roles, :metadatarbs, :metadatajsons,
                :cookbooks, :attributes, :libraries, :resources, :providers

  def initialize(opts = {})
    @recipes = opts[:recipes] || {}
    @recipejsons = opts[:recipejsons] || {}
    @roles = opts[:roles] || {}
    @metadatarbs = opts[:metadatarbs] || {}
    @metadatajsons = opts[:metadatajsons] || {}
    @cookbooks = opts[:cookbooks] || {}
    @attributes = opts[:attributes] || {}
    @libraries = opts[:libraries] || {}
    @resources = opts[:resources] || {}
    @providers = opts[:providers] || {}
  end
end
