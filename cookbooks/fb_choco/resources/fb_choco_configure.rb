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
# Resource:: fb_choco_configure

resource_name :fb_choco_configure
provides :fb_choco_configure, :os => 'windows'
unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :change
property :config,   Hash,
         :coerce => proc { |i|
                      desired = {}
                      i.map do |k, v|
                        desired[k] = v.to_s
                      end

                      desired = Helpers.config_list.merge(desired)

                      desired
                    }
property :sources,  Hash,
         :coerce => proc { |v|
                      desired = {}
                      v.map do |e|
                        key, enforce = if e.is_a?(Hash)
                                         s = e.to_a
                                         [s[0], s[1]]
                                       elsif e.is_a?(Array)
                                         [e[0], e[1]]
                                       end

                        if enforce.is_a?(Chef::Node::ImmutableMash)
                          enforce = enforce.to_h
                        end

                        key = key.to_s

                        if enforce['source']
                          enforce['value'] = enforce['source']
                        end

                        if enforce['value']
                          enforce['source'] = enforce['value']
                        end

                        desired[key] = enforce
                      end

                      desired
                    }

property :features, Hash,
         :coerce => proc { |i|
                      desired = {}
                      i.map do |k, v|
                        desired[k] = v
                      end

                      desired = Helpers.feature_list.merge(desired)

                      desired
                    }
# this is for the `load_current_value`
class Helpers
  extend ::FB::Choco::State::Config
end

load_current_value do
  Helpers.load_config

  config   Helpers.config_list
  sources  Helpers.source_list
  features Helpers.feature_list
end

action_class do
  # this is for the actions
  class Helpers
    extend ::FB::Choco::State::Config
  end

  def blocklist_sources
    node['fb_choco']['sources'].each do |feed, source_info|
      url = source_info['source']
      if node['fb_choco']['source_blocklist'].include?(url)
        Chef::Log.warn(
          "[#{cookbook_name}]: Not adding #{feed} as a choco source " +
          "as #{url} is blocklisted.",
        )
        new_values =
          node.default['fb_choco']['sources'].to_h.reject { |k, _| k == feed }
        node.default['fb_choco']['sources'] = new_values
      end
    end
  end
end

action :change do
  blocklist_sources

  converge_if_changed :sources do
    node['fb_choco']['sources'].each do |feed, source_info|
      chocolatey_source feed do
        source source_info['source']
        action :add
      end
    end

    # Remove the difference between the incoming and current sources.
    (current_resource.sources.keys - new_resource.sources.keys).each do |feed|
      chocolatey_source feed do
        action :remove
      end
    end
  end

  converge_if_changed :config do
    node['fb_choco']['config'].each do |k, v|
      val = v.to_s
      next if val.empty?

      chocolatey_config k do
        value val
        action :set
      end
    end
  end

  converge_if_changed :features do
    node.default['fb_choco']['features'].each do |feature, enabled|
      resource_action = :disable
      resource_action = :enable if enabled
      chocolatey_feature feature do
        action resource_action
      end
    end
  end
end
