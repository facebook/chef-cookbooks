# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

require 'chefspec'
require 'chefspec/lib/chefspec/matchers/render_file_matcher.rb'

$VERBOSE = nil

module FB
  class Spec
    def self.fbspec_init(cookbook_path, platforms)
      RSpec.configure do |config|
        config.expect_with :rspec do |c|
          c.syntax = [:should, :expect]
        end
        config.mock_with :rspec do |c|
          c.syntax = [:should, :expect]
        end
        config.cookbook_path = cookbook_path
      end
      FB::Spec.configure do |config|
        config.platforms = platforms
      end
    end

    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :platforms

      def initialize
        @platforms = {}
      end
    end

    class Testcase
      include RSpec::Matchers
      def initialize(config)
        @config = config
      end

      # Local sites should monkeypatch this method if necessary
      def chef_run_block_extras(_node); end

      def chef_run(**extra_args)
        extra_args[:step_into] ||= []
        extra_args[:step_into] << 'whyrun_safe_ruby_block'
        extra_args[:step_into].uniq!
        runner_args = {
          :platform => @config['platform'],
          :version => @config['version'],
          :platform_group => 'xxxx',
        }.merge(extra_args)
        ChefSpec::SoloRunner.new(runner_args) do |node|
          chef_run_block_extras(node)
          yield(node) if block_given?
        end
      end

      def fixture_path(path, name)
        File.join(
          File.dirname(caller(2..2).first.split(':').first),
          'fixtures', path, name
        )
      end

      def platform
        @config[:platform_group]
      end

      def fixture(name)
        # look in fb_cookbooks/spec/fixtures/centos6/
        profile_path = fixture_path(
          self.platform.to_s, name
        )
        # look in fb_cookbook/spec/fixtures/default/ (fallback)
        default_path = fixture_path('default', name)

        path = File.exist?(profile_path) ? profile_path : default_path
        begin
          File.read(path)
        rescue StandardError
          puts "Fixture #{name} not found " +
            "(tried: #{profile_path}, #{default_path})"
          raise
        end
      end
    end

    class Runner
      def initialize(config, &block)
        RSpec.describe config[:described_recipe] do
          config[:supported].each do |platform|
            FB::Spec.configuration.platforms[platform].each do |os|
              os[:platform_group] = platform
              tags = config[:supported].map do |x|
                { x => false }
              end.reduce({}, :merge)
              tags[platform] = true
              config[:xxx] = 1
              context "#{platform} (#{os['version']})", tags do
                instance_exec(
                  FB::Spec::Testcase.new(os),
                  &block
                )
              end
            end
          end
        end
      end
    end
  end
end

def recipe(name, options = [], &block)
  if options.include?(:supported)
    supported = [*options[:supported]].map(&:to_sym)
  else
    supported = FB::Spec.configuration.platforms.keys
  end

  if options.include?(:unsupported)
    supported -= [*options[:unsupported]].map(&:to_sym)
  end

  FB::Spec::Runner.new(
    { :supported => supported, :described_recipe => name },
    &block
  )
end
