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
# Cookbook Name:: fb_choco
# Libraries:: state

require 'rexml/document'

module FB
  class Choco
    module State
      module Config
        CONFIG   = '//config/add'.freeze
        SOURCES  = '//sources/source'.freeze
        FEATURES = '//features/feature'.freeze
        CONFIG_LOC = 'C:\ProgramData\chocolatey\config\chocolatey.config'.freeze

        def config_state
          @config_state ||= REXML::Document.new(@raw_config)
        end

        def load_config
          @raw_config ||= IO.read(CONFIG_LOC)
        rescue StandardError => e
          Chef::Log.warn(e)
        end

        def xml_value(xpath, new_value: nil)
          REXML::XPath.each(config_state, xpath) do |element|
            return element.attributes['value'] unless new_value

            element.attributes['value'] = new_value
          end
        end

        def config_list
          REXML::XPath.each(config_state, CONFIG).with_object({}) do |e, m|
            m[e.attributes['key']] = e.attributes['value']
          end
        end

        def feature_list
          REXML::XPath.each(config_state, FEATURES).with_object({}) do |e, m|
            m[e.attributes['name']] =
              e.attributes['enabled'].to_s.downcase == 'true'
          end
        end

        def source_list
          REXML::XPath.each(config_state, SOURCES).with_object({}) do |e, m|
            m[e.attributes['id']] = {
              'source'   => e.attributes['value'],
              'value'    => e.attributes['value'],
            }
          end
        end
      end
    end
  end
end
