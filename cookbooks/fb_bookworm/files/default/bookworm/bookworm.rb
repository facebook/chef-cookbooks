#!/opt/chef-workstation/embedded/bin/ruby
# Copyright (c) 2022-present, Meta, Inc.
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

require 'optparse'

parser = ::OptionParser.new

parser.banner = 'Usage: bookworm.rb [options]'

# TODO(dcrosby) explicitly output to stdout?
# parser.on(
#   '--output TYPE',
#   '(STUB) Configure output type for report. Options: plain (default), JSON',
# )

parser.on(
  '--report CLASS',
  "Give the (class) name of the report you'd like",
)

parser.on(
  '--list-reports',
  'Get the (class) names of available reports',
)

parser.on(
  '--list-rules',
  'Get the (class) names of available inferrence rules',
)

parser.separator ''
parser.separator 'Debugging options:'

# TODO(dcrosby) add verbose mode
# parser.on(
#   '--verbose',
#   'Enable verbose mode',
# )

# TODO(dcrosby) get ruby-prof working
# parser.on(
#   '--profiler',
#   '(WIP) Enable profiler for performance debugging',
# )

parser.on(
  '--irb-config-step',
  'Open IRB REPL after loading configuration',
)

parser.on(
  '--irb-crawl-step',
  'Open IRB REPL after crawler has run',
)

parser.on(
  '--irb-infer-step',
  'Open IRB REPL after inferrence has run',
)

parser.on(
  '--irb-report-step',
  'Open IRB REPL after report is generated',
)

options = {}
parser.parse!(:into => options)

# TODO(dcrosby) get ruby-prof working
# if options[:profiler]
#   require 'ruby-prof'
#   RubyProf.start
# end

# We require the libraries *after* the profiler has a chance to start,
# also means faster `bookworm -h` response
require 'set'
require_relative 'exceptions'
require_relative 'keys'
require_relative 'configuration'
require_relative 'crawler'
require_relative 'knowledge_base'
require_relative 'infer_engine'
require_relative 'report_builder'

module Bookworm
  class ClassLoadError < RuntimeError; end
end

# TODO(dcrosby) read CLI for config file path
config = Bookworm::Configuration.new
if config.source_dirs.nil? || config.source_dirs.empty?
  fail 'configuration source_dirs cannot be empty'
end

report_src_dirs = ["#{__dir__}/reports/"]
if Dir.exist? "#{config.system_contrib_dir}/reports"
  report_src_dirs.append "#{config.system_contrib_dir}/reports"
end

if options[:"list-reports"]
  report_src_dirs.each do |d|
    Bookworm.load_reports_dir d
  end

  puts Bookworm::Reports.constants.map { |x|
    "#{x}\t#{Module.const_get("Bookworm::Reports::#{x}")&.description}"
  }.sort.join("\n")
  exit
end

rule_src_dirs = ["#{__dir__}/rules/"]
if Dir.exist? "#{config.system_contrib_dir}/rules/"
  rule_src_dirs.append "#{config.system_contrib_dir}/rules/"
end

if options[:"list-rules"]
  rule_src_dirs.each do |d|
    Bookworm.load_rules_dir d
  end
  puts Bookworm::InferRules.constants.map { |x|
    "#{x}\t#{Module.const_get("Bookworm::InferRules::#{x}")&.description}"
  }.sort.join("\n")
  exit
end

binding.irb if options[:"irb-config-step"] # rubocop:disable Lint/Debugger

report_name = options[:report]
unless report_name
  puts "No report name given, take a look at bookworm --list-reports\n\n"
  puts parser.help
  exit(false)
end
report_src_dirs.each do |d|
  begin
    Bookworm.load_report_class report_name, :dir => d
    break
  rescue Bookworm::ClassLoadError
    # puts "Unable to load report #{report_name}, take a look at bookworm --list-reports\n\n"
  end
end
unless Bookworm::Reports.const_defined?(report_name.to_sym)
  puts "Unable to load report #{report_name}, take a look at bookworm --list-reports\n\n"
  puts parser.help
  exit(false)
end

# To keep processing to only what is needed, the rules are specified within
# the report. From those rules, we gather the keys that actually need to be
# crawled (instead of crawling everything)
# TODO(dcrosby) recursively check rules for dependency keys
rules = Bookworm.get_report_rules(report_name)
rules.each do |rule|
  rule_src_dirs.each do |d|
    begin
      Bookworm.load_rule_class rule, :dir => d
      break
    rescue Bookworm::ClassLoadError
      # puts "Unable to load rule #{rule}, take a look at bookworm --list-rules\n\n"
    end
  end
  unless Bookworm::InferRules.const_defined?(rule.to_sym)
    puts "Unable to load rule #{rule}, take a look at bookworm --list-rules\n\n"
    puts parser.help
    exit(false)
  end
end
keys = rules.map { |r| Module.const_get("Bookworm::InferRules::#{r}")&.keys }.flatten.uniq

# The crawler determines the files that need to be processed
# It currently converts Ruby source files to AST/objects (that may change)
processed_files = Bookworm::Crawler.new(config, :keys => keys).processed_files

# The knowledge base is what we know about the files (AST, paths,
# digested information from inference rules, etc)
knowledge_base = Bookworm::KnowledgeBase.new(processed_files)

binding.irb if options[:"irb-crawl-step"] # rubocop:disable Lint/Debugger

# InferEngine takes the crawler output in the knowledge base and runs a series
# of Infer rules against the source AST (and more) to build a knowledge base
# around the source
# It runs classes within the Bookworm::InferRules module namespace
engine = Bookworm::InferEngine.new(knowledge_base, rules)
knowledge_base = engine.knowledge_base

binding.irb if options[:"irb-infer-step"] # rubocop:disable Lint/Debugger

# The ReportBuilder takes the completed knowledge base and generates a report
# with each class in the Bookworm::Reports module namespace

Bookworm::ReportBuilder.new(knowledge_base, report_name)

binding.irb if options[:"irb-report-step"] # rubocop:disable Lint/Debugger

# TODO(dcrosby) get ruby-prof working
# if options[:profiler]
#   result = RubyProf.stop
#   printer = RubyProf::FlatPrinter.new(result)
#   printer.print($stdout)
# end
