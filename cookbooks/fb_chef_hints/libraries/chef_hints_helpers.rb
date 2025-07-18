# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

require 'chef/log'

module FB
  # Allowed hints and sources are considered consistent data. When deploying
  # fb_chef_hints, create one (and only one) settings cookbook to define these
  # constants.
  class ChefHintsSiteData
    # No hints allowed by default. Define this in your settings cookbook.
    # ALLOWED_HINTS = [].freeze

    # No override providers allowed by default. Define this in your settings
    # cookbook.
    # ALLOWED_SOURCES = [].freeze
  end

  class ChefHints
    HINTS_BASE = 'attribute_hints'.freeze

    def self.valid_hints?(hints, allowed_sources = nil)
      Chef::Log.debug("fb_chef_hints: validating #{hints}")
      begin
        allowed_sources ||= FB::ChefHintsSiteData::ALLOWED_SOURCES
      rescue NameError
        allowed_sources = []
      end
      unless allowed_sources.is_a?(Array)
        fail 'fb_chef_hints: allowed_sources must be an Array (actual: ' +
          "#{allowed_sources.class})"
      end
      %w{source hint}.each do |field|
        unless hints[field]
          Chef::Log.error(
            "fb_chef_hints: hint #{hints} is missing mandatory field: " +
            field,
          )
          return false
        end
      end
      if allowed_sources.include?(hints['source'])
        Chef::Log.debug(
          "fb_chef_hints: hint source #{hints['source']} is allowed, " +
          'proceeding',
        )
        return true
      else
        Chef::Log.error(
          "fb_chef_hints: hint source #{hints['source']} is not allowed, " +
          'see fb_chef_hints/README.md for details.',
        )
        return false
      end
    end

    def self.filter_hints(hints, allowed_hints = nil)
      begin
        allowed_hints ||= FB::ChefHintsSiteData::ALLOWED_HINTS
      rescue NameError
        allowed_hints = []
      end
      unless allowed_hints.is_a?(Array)
        fail 'fb_chef_hints: allowed_hints must be an Array (actual: ' +
          "#{allowed_hints.class})"
      end
      FB::Helpers.filter_hash(hints, allowed_hints)
    end

    def self.apply_hint(node, path)
      Chef::Log.debug("fb_chef_hints: processing #{path}")
      hint = FB::Helpers.parse_json_file(path, Hash, true)
      if FB::ChefHints.valid_hints?(hint)
        filtered_hint = FB::ChefHints.filter_hints(hint['hint'])

        if filtered_hint.empty?
          Chef::Log.warn(
            "fb_chef_hints: nothing to apply for hint file #{path}",
          )
        else
          Chef::Log.info(
            "fb_chef_hints: applying hint #{filtered_hint} from hint file " +
           "#{path} for #{hint['source']}",
          )
          # Explicitly overwrite leaf hashes when merging
          FB::Helpers.merge_hash!(node.default, filtered_hint, true)
        end
      else
        Chef::Log.warn("fb_chef_hints: skipping invalid hint files #{path}")
      end
    end
  end
end
