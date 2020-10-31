#
# Copyright (c) 2020-present, Facebook, Inc.
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

module FB
  class Fluentbit
    def self.plugins_from_node(node)
      plugins = []
      Plugin::TYPES.each do |plugin_type|
        node['fb_fluentbit'][plugin_type].each do |name, configs|
          configs.each do |human_name, config|
            plugins << Plugin.new(
              :type => plugin_type,
              :name => name,
              :human_name => human_name,
              :config => config,
            )
          end
        end
      end
      plugins
    end

    def self.external_plugins_from_node(node)
      node['fb_fluentbit']['external'].map do |name, config|
        ExternalPlugin.new(name, config['package'], config['path'])
      end
    end

    def self.parsers_from_node(node)
      node['fb_fluentbit']['parser'].map do |name, config|
        Parser.new(name, config)
      end
    end

    class ExternalPlugin
      attr_reader :name, :package, :path

      def initialize(name, package, path)
        @name = name
        @package = package
        @path = path
      end

      def validate
        if @package.nil?
          fail "fb_fluentbit: external plugin '#{@name}' missing required " +
            'key \'package\''
        end
        if @path.nil?
          fail "fb_fluentbit: external plugin '#{@name}' missing required " +
            'key \'path\''
        end
      end
    end

    class Parser
      attr_reader :name, :config

      def initialize(name, config)
        @name = name
        @config = config
      end

      def format
        if @config.key?('format')
          @config['format']
        elsif @config.key?('Format')
          @config['Format']
        end
      end

      def validate
        if format.nil?
          fail "fb_fluentbit: parser '#{@name}' does not define format"
        end
      end
    end

    class Plugin
      # Supported types of plugins.
      TYPES = %w{input filter output}.freeze

      attr_reader :type, :name, :human_name, :config

      def initialize(type:, name:, human_name:, config:)
        @type = type
        @name = name
        @human_name = human_name
        @config = config
      end

      def validate(parsers)
        if @type == 'filter' && @name == 'parser'
          parser_name = if @config.key?('Parser')
                          @config['Parser']
                        elsif @config.key?('parser')
                          @config['parser']
                        end
          unless parsers.map(&:name).include?(parser_name)
            fail "fb_fluentbit: plugin '#{@human_name}' is using undefined " +
              "parser #{parser_name}"
          end
        end
      end

      # Helper struct for defining config file key/value pairs.
      Config = Struct.new(:key, :value)

      #
      # Fluentbit's config is a little odd. It mostly seems to be key/value
      # based, with the following caveats
      #   * Keys can repeat (which seems to OR all the values)
      #   * Values can sometimes be key/value based.
      #
      # In order to support these two, the following API decisions were made:
      #   * Multiple keys are supported by setting cookbook API values to lists.
      #     We then replicate each key/value pair, one per value in the list.
      #   * Values that are key/values pairs are separated by = and replicated
      #     like the above.
      #   * Values can be callable by passing in 'procs' (similar to other
      #     cookbooks).
      #
      # See spec tests for examples of what this looks like.
      #
      def serialize_config
        final_conf = []
        config.each do |key, val|
          if val.respond_to?(:call)
            final_conf << Config.new(key, val.call)
          elsif val.is_a?(Array)
            final_conf += val.map { |v| Config.new(key, v) }

          # Hashes can have some inner nesting, but only to a certain point.
          elsif val.is_a?(Hash)
            val.each do |k, v|
              if v.is_a?(Array)
                final_conf += v.map { |e| Config.new(key, "#{k}=#{e}") }
              else
                final_conf << Config.new(key, "#{k}=#{v}")
              end
            end
          else
            final_conf << Config.new(key, val)
          end
        end
        final_conf
      end
    end
  end
end
