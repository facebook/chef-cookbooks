# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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
#

default_action :load

property :module_name, :kind_of => String, :name_property => true
property :verbose, :kind_of => [TrueClass, FalseClass], :default => false
property :timeout, :kind_of => Integer, :default => 300
property :fallback, :kind_of => [TrueClass, FalseClass], :default => false
property :module_params, :kind_of => [String, Array], :required => false

action_class do
  def modprobe_module(new_resource, unload)
    module_name = new_resource.module_name
    params = [new_resource.module_params].flatten.compact
    timeout = new_resource.timeout
    verbose = new_resource.verbose
    fallback = new_resource.fallback

    flags = []
    flags << '-v' if verbose
    flags << '-r' if unload

    # Correctly handle built-in modules. If no parameters were supplied, we
    # just return true. If the caller supplied parameters, we fail the Chef run
    # and ask them to fix their cookbook, since we can't apply them.
    if ::File.exist?("/sys/module/#{module_name}")
      unless ::File.exist?("/sys/module/#{module_name}/initstate")
        ::Chef::Log.warn(
          "fb_modprobe called on built-in module '#{module_name}'",
        )
        unless params.empty?
          fail <<-FAIL
          Cannot set parameters for built-in module '#{module_name}'!
          Parameters for built-in modules must be passed on the kernel cmdline.
          Prefix the parameter with the module name and a dot.
          Examples: "ipv6.autoconf=1", "mlx4_en.udp_rss=1"
          FAIL
        end

        return True
      end
    end

    command = ['/sbin/modprobe'] + flags + [module_name] + params

    # Sometimes modprobe fails, like when the module was uninstalled
    if fallback && unload
      command << '||'
      command << 'rmmod'
      command << '-v' if verbose
      command << module_name
    end

    execute command.join(' ') do
      action :run
      notifies :reload, 'ohai[reload kernel]', :immediately
      timeout timeout
    end
  end
end

action :load do
  if FB::Modprobe.module_loaded?(new_resource.module_name)
    Chef::Log.debug("#{new_resource}: Module already loaded")
  else
    modprobe_module(new_resource, false)
  end
end

action :unload do
  if !FB::Modprobe.module_loaded?(new_resource.module_name)
    Chef::Log.debug("#{new_resource}: Module already unloaded")
  else
    modprobe_module(new_resource, true)
  end
end
