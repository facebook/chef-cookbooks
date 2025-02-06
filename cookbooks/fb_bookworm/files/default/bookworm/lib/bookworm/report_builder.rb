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
require 'json'
require 'pathname'

module Bookworm
  class BaseReport
    class << self
      {
        'description' => '',
        'needs_rules' => [],
      }.each do |attribute, default_value|
        instance_variable_set("@#{attribute}".to_sym, default_value)
        define_method(attribute.to_sym) do |val = nil|
          instance_variable_set("@#{attribute}", val) unless val.nil?
          instance_variable_get("@#{attribute}")
        end
      end
    end

    def initialize(knowledge_base)
      @kb = knowledge_base
      output
    end

    def to_plain
      ''
    end

    def to_json(*_args)
      JSON.dump({})
    end

    def default_output
      :to_plain
    end

    def output
      send(default_output)
    end
  end

  # Initialize constant for Bookworm::Reports
  module Reports; end

  class ReportBuilder
    def initialize(knowledge_base, report_name)
      klass = Module.const_get("Bookworm::Reports::#{report_name}")
      output = klass.new(knowledge_base).output

      puts output
    end
  end

  def self.get_report_rules(report_name)
    klass = Module.const_get("Bookworm::Reports::#{report_name}")
    klass.needs_rules
  end

  def self.load_report_class(name, dir: '')
    f = File.read "#{dir}/#{name.to_sym}.rb"
    ::Bookworm::Reports.const_set(name.to_sym, ::Class.new(::Bookworm::BaseReport))
    ::Bookworm::Reports.const_get(name.to_sym).class_eval(f)
  rescue StandardError
    raise Bookworm::ClassLoadError
  end

  def self.load_reports_dir(dir)
    files = Dir.glob("#{dir}/*.rb")
    files.each do |f|
      name = Pathname(f).basename.to_s.gsub('.rb', '')
      begin
        Bookworm.load_report_class name, :dir => dir
      rescue Bookworm::ClassLoadError
        puts "Unable to load report #{f}"
        exit(false)
      end
    end
  end
end
