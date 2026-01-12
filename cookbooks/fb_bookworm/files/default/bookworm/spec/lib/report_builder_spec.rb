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
require 'bookworm/exceptions'
require 'bookworm/report_builder'

describe Bookworm::BaseReport do
  describe 'class attributes' do
    it 'has default nil description on subclass' do
      test_class = Class.new(described_class)
      expect(test_class.description).to be_nil
    end

    it 'has default nil needs_rules on subclass' do
      test_class = Class.new(described_class)
      expect(test_class.needs_rules).to be_nil
    end

    it 'allows setting description' do
      test_class = Class.new(described_class)
      test_class.description 'Test report'
      expect(test_class.description).to eq('Test report')
    end

    it 'allows setting needs_rules' do
      test_class = Class.new(described_class)
      test_class.needs_rules ['RuleOne', 'RuleTwo']
      expect(test_class.needs_rules).to eq(['RuleOne', 'RuleTwo'])
    end
  end

  describe '#initialize' do
    it 'stores knowledge_base' do
      mock_kb = double('KnowledgeBase')
      report = described_class.new(mock_kb)
      expect(report.instance_variable_get(:@kb)).to eq(mock_kb)
    end

    it 'calls output on initialization' do
      test_class = Class.new(described_class) do
        def output
          @output_called = true
          super
        end
      end
      report = test_class.new(nil)
      expect(report.instance_variable_get(:@output_called)).to eq(true)
    end
  end

  describe '#to_plain' do
    it 'returns empty string by default' do
      report = described_class.new(nil)
      expect(report.to_plain).to eq('')
    end
  end

  describe '#to_json' do
    it 'returns empty JSON object by default' do
      report = described_class.new(nil)
      expect(report.to_json).to eq('{}')
    end
  end

  describe '#default_output' do
    it 'returns :to_plain by default' do
      report = described_class.new(nil)
      expect(report.default_output).to eq(:to_plain)
    end
  end

  describe '#output' do
    it 'calls the method returned by default_output' do
      report = described_class.new(nil)
      expect(report.output).to eq('')
    end

    it 'can be overridden via default_output' do
      test_class = Class.new(described_class) do
        def default_output
          :to_json
        end
      end
      report = test_class.new(nil)
      expect(report.output).to eq('{}')
    end
  end
end

describe 'Bookworm.load_report_class' do
  after do
    if Bookworm::Reports.const_defined?(:TestReport)
      Bookworm::Reports.send(:remove_const, :TestReport)
    end
  end

  it 'creates a new class under Bookworm::Reports' do
    report_content = <<~RUBY
      description 'A test report'
      needs_rules ['TestRule']
    RUBY
    allow(File).to receive(:read).with('/fake/dir/TestReport.rb').and_return(report_content)

    Bookworm.load_report_class(:TestReport, :dir => '/fake/dir')

    expect(Bookworm::Reports.const_defined?(:TestReport)).to eq(true)
    expect(Bookworm::Reports::TestReport.superclass).to eq(Bookworm::BaseReport)
    expect(Bookworm::Reports::TestReport.description).to eq('A test report')
    expect(Bookworm::Reports::TestReport.needs_rules).to eq(['TestRule'])
  end

  it 'raises ClassLoadError on failure' do
    allow(File).to receive(:read).and_raise(Errno::ENOENT)

    expect do
      Bookworm.load_report_class(:NonexistentReport, :dir => '/fake/dir')
    end.to raise_error(Bookworm::ClassLoadError)
  end
end

describe 'Bookworm.get_report_rules' do
  before do
    Bookworm::Reports.const_set(:MockReport, Class.new(Bookworm::BaseReport))
    Bookworm::Reports::MockReport.needs_rules ['RuleA', 'RuleB']
  end

  after do
    Bookworm::Reports.send(:remove_const, :MockReport)
  end

  it 'returns the needs_rules for a report' do
    expect(Bookworm.get_report_rules('MockReport')).to eq(['RuleA', 'RuleB'])
  end
end

describe 'Bookworm.load_reports_dir' do
  after do
    [:ReportOne, :ReportTwo].each do |name|
      if Bookworm::Reports.const_defined?(name)
        Bookworm::Reports.send(:remove_const, name)
      end
    end
  end

  it 'loads all .rb files from a directory' do
    allow(Dir).to receive(:glob).with('/fake/reports/*.rb').and_return(
      ['/fake/reports/ReportOne.rb', '/fake/reports/ReportTwo.rb'],
    )
    allow(File).to receive(:read).with('/fake/reports/ReportOne.rb').and_return(
      "description 'Report one'",
    )
    allow(File).to receive(:read).with('/fake/reports/ReportTwo.rb').and_return(
      "description 'Report two'",
    )

    Bookworm.load_reports_dir('/fake/reports')

    expect(Bookworm::Reports::ReportOne.description).to eq('Report one')
    expect(Bookworm::Reports::ReportTwo.description).to eq('Report two')
  end
end

describe Bookworm::Reports do
  it 'is a module' do
    expect(Bookworm::Reports).to be_a(Module)
  end
end

describe Bookworm::ReportBuilder do
  before do
    Bookworm::Reports.const_set(:TestBuilderReport, Class.new(Bookworm::BaseReport))
    Bookworm::Reports::TestBuilderReport.class_eval do
      def to_plain
        'test output'
      end
    end
  end

  after do
    Bookworm::Reports.send(:remove_const, :TestBuilderReport)
  end

  it 'prints report output' do
    mock_kb = double('KnowledgeBase')
    expect { Bookworm::ReportBuilder.new(mock_kb, 'TestBuilderReport') }.to output("test output\n").to_stdout
  end
end
