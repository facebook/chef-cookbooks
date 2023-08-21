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
module Bookworm
  class CLIParser
    def initialize
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
        'Get the (class) names of available inference rules',
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
        'Open IRB REPL after inference has run',
      )

      parser.on(
        '--irb-report-step',
        'Open IRB REPL after report is generated',
      )

      @parser = parser
    end

    def help
      @parser.help
    end

    def parse
      options = {}
      @parser.parse(ARGV, :into => options)
      options
    end
  end
end
parser = Bookworm::CLIParser.new
options = parser.parse
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

  # Class to hold state of a Bookworm run
  class Run
    attr_reader :cli_help_message, :config, :report_src_dirs, :rule_src_dirs, :action, :irb_breakpoints, :report_name

    def initialize(cli_options, cli_help_message)
      @cli_help_message = cli_help_message
      validate_cli_args(cli_options)
      set_irb_breakpoints(cli_options)
      generate_config
      validate_config_file
      load_src_dirs
      determine_action(cli_options)
      binding.irb if irb_breakpoint?('config') # rubocop:disable Lint/Debugger
    end

    def set_irb_breakpoints(options)
      @irb_breakpoints = []
      %w{config crawl infer report}.each do |bp|
        @irb_breakpoints << bp if options["irb-#{bp}-step".to_sym]
      end
    end

    def irb_breakpoint?(str)
      @irb_breakpoints.include?(str)
    end

    def do_action
      case @action
      when :"list-reports"
        list_reports
      when :"list-rules"
        list_rules
      when :report
        generate_report
      end
    end

    def determine_action(options)
      [:"list-reports", :"list-rules", :report].each do |a|
        if options[a]
          if @action
            cli_fail 'Multiple actions specified, check your arguments'
          else
            @action = a
          end
        end
      end
      @report_name = options[:report]
    end

    def generate_config
      # TODO(dcrosby) read CLI for config file path
      @config = Bookworm::Configuration.new
    end

    def cli_fail(msg)
      puts "#{msg}\n\n#{@cli_help_message}"
      exit(false)
    end

    def validate_cli_args(options)
      unless options[:"list-reports"] || options[:"list-rules"]
        unless options[:report]
          cli_fail 'No report name given, take a look at bookworm --list-reports'
        end
      end
    end

    def validate_config_file
      if @config.source_dirs.nil? || @config.source_dirs.empty?
        fail 'configuration source_dirs cannot be empty'
      end
    end

    def load_src_dirs
      @report_src_dirs = ["#{__dir__}/reports/"]
      if Dir.exist? "#{@config.system_contrib_dir}/reports"
        @report_src_dirs.append "#{@config.system_contrib_dir}/reports"
      end
      @rule_src_dirs = ["#{__dir__}/rules/"]
      if Dir.exist? "#{@config.system_contrib_dir}/rules/"
        @rule_src_dirs.append "#{@config.system_contrib_dir}/rules/"
      end
    end

    def list_reports
      @report_src_dirs.each do |d|
        Bookworm.load_reports_dir d
      end

      puts Bookworm::Reports.constants.map { |x|
        "#{x}\t#{Module.const_get("Bookworm::Reports::#{x}")&.description}"
      }.sort.join("\n")
    end

    def list_rules
      @rule_src_dirs.each do |d|
        Bookworm.load_rules_dir d
      end
      puts Bookworm::InferRules.constants.map { |x|
        "#{x}\t#{Module.const_get("Bookworm::InferRules::#{x}")&.description}"
      }.sort.join("\n")
    end

    def generate_report
      load_classes_for_report
      crawl_source
      make_inferences
      build_report
    end

    def load_classes_for_report
      @report_src_dirs.each do |d|

        Bookworm.load_report_class @report_name, :dir => d
        break
      rescue Bookworm::ClassLoadError
        # puts "Unable to load report #{report_name}, take a look at bookworm --list-reports\n\n"

      end
      unless Bookworm::Reports.const_defined?(@report_name.to_sym)
        cli_fail "Unable to load report #{@report_name}, take a look at bookworm --list-reports"
      end

      # To keep processing to only what is needed, the rules are specified within
      # the report. From those rules, we gather the keys that actually need to be
      # crawled (instead of crawling everything)
      # TODO(dcrosby) recursively check rules for dependency keys
      @rules = Bookworm.get_report_rules(@report_name)
      @rules.each do |rule|
        @rule_src_dirs.each do |d|

          Bookworm.load_rule_class rule, :dir => d
          break
        rescue Bookworm::ClassLoadError
          # puts "Unable to load rule #{rule}, take a look at bookworm --list-rules\n\n"

        end
        unless Bookworm::InferRules.const_defined?(rule.to_sym)
          cli_fail "Unable to load rule #{rule}, take a look at bookworm --list-rules"
        end
      end
    end

    def crawl_source
      # Determine necessary keys to crawl
      keys = @rules.map { |r| Module.const_get("Bookworm::InferRules::#{r}")&.keys }.flatten.uniq

      # The crawler determines the files that need to be processed
      # It currently converts Ruby source files to AST/objects (that may change)
      processed_files = Bookworm::Crawler.new(config, :keys => keys).processed_files

      # The knowledge base is what we know about the files (AST, paths,
      # digested information from inference rules, etc)
      @knowledge_base = Bookworm::KnowledgeBase.new(processed_files)

      binding.irb if irb_breakpoint?('crawl') # rubocop:disable Lint/Debugger
    end

    def make_inferences
      # InferEngine takes the crawler output in the knowledge base and runs a series
      # of Infer rules against the source AST (and more) to build a knowledge base
      # around the source
      # It runs classes within the Bookworm::InferRules module namespace
      engine = Bookworm::InferEngine.new(@knowledge_base, @rules)
      @knowledge_base = engine.knowledge_base

      binding.irb if irb_breakpoint?('infer') # rubocop:disable Lint/Debugger
    end

    def build_report
      # The ReportBuilder takes a knowledge base and generates a report
      # with each class in the Bookworm::Reports module namespace
      Bookworm::ReportBuilder.new(@knowledge_base, @report_name)

      binding.irb if irb_breakpoint?('report') # rubocop:disable Lint/Debugger
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  run = Bookworm::Run.new(options, parser.help)
  run.do_action
end

# TODO(dcrosby) get ruby-prof working
# if options[:profiler]
#   result = RubyProf.stop
#   printer = RubyProf::FlatPrinter.new(result)
#   printer.print($stdout)
# end
