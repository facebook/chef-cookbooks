# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2021-present, Facebook, Inc.
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

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :run

action :run do
  DEFAULTS_DIR = '/etc/dnf/modules.defaults.d'.freeze
  MODS_DIR = '/etc/dnf/modules.d'.freeze

  node['fb_dnf']['modules'].each do |name, mod|
    template "#{DEFAULTS_DIR}/#{name}.yaml" do
      owner node.root_user
      group node.root_group
      mode '0644'
      source 'fb_modules.yaml.erb'
      variables({ :name => name, :module => mod })
    end

    if mod['enable']
      unless mod['stream']
        fail "fb_dnf[modularity]: Need to specify 'stream' property " +
          "for module '#{name}'"
      end
      template "#{MODS_DIR}/#{name}.module" do
        owner node.root_user
        group node.root_group
        mode '0644'
        source 'fb_modules.module.erb'
        variables({ :name => name, :module => mod })
        notifies :run, 'whyrun_safe_ruby_block[clean chef yum metadata]',
                 :immediately
      end
    end
  end

  Dir.glob("#{DEFAULTS_DIR}/*.yaml").each do |modfile|
    name = ::File.basename(modfile, '.yaml')
    next if node['fb_dnf']['modules'][name]
    file modfile do
      action :delete
    end
  end

  Dir.glob("#{MODS_DIR}/*.module").each do |modfile|
    name = ::File.basename(modfile, '.module')
    mod = node['fb_dnf']['modules'][name]
    next if mod && mod['enable']
    file modfile do
      action :delete
      notifies :run, 'whyrun_safe_ruby_block[clean chef yum metadata]',
               :immediately
    end
  end
end
