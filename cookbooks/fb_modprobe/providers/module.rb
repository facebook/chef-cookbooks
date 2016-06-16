# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

# Note that we cannot use `use_inline_resources` because of the ohai
# notification below.... later versions of Chef will allow that though.

def whyrun_supported?
  true
end

def modprobe_module(module_name, params, timeout, verbose, unload)
  flags = []
  flags << '-v' if verbose
  flags << '-r' if unload

  params = [params].flatten.compact

  # Correctly handle built-in modules. If no parameters were supplied, we just
  # return true. If the caller supplied parameters, we fail the Chef run and ask
  # them to fix their cookbook, since we can't apply them.
  if ::File.exist?("/sys/modules/#{module_name}")
    unless ::File.exist?("/sys/modules/#{module_name}/initstate")
      ::Chef::Log.warn("fb_modprobe called on built-in module '#{module_name}'")
      unless params.empty?
        fail <<-FAIL
          Cannot set parameters for built-in module '#{module_name}'!
          Parameters for built-in modules must be passed on the kernel cmdline.
          Prefix the parameter with the module name and a dot.
          Examples: "ipv6.autoconf=1", "mlx4_en.udp_rss=1
          Contact the kernel oncall if you have any questions about this.
        FAIL
      end
      return True
    end
  end

  args = flags + [module_name] + params

  execute "modprobe #{module_name}" do
    command "/sbin/modprobe #{args.join(' ')}"
    action :run
    notifies :reload, 'ohai[reload kernel]', :immediately
    timeout timeout
  end
end

action :load do
  if FB::Modprobe.module_loaded?(new_resource.module_name)
    Chef::Log.debug("#{new_resource}: Module already loaded")
  else
    converge_by("Load #{new_resource.module_name}") do
      modprobe_module(new_resource.module_name,
                      new_resource.module_params,
                      new_resource.timeout,
                      new_resource.verbose, false)
    end
    new_resource.updated_by_last_action(true)
  end
end

action :unload do
  if !FB::Modprobe.module_loaded?(new_resource.module_name)
    Chef::Log.debug("#{new_resource}: Module already unloaded")
  else
    converge_by("Unload #{new_resource.module_name}") do
      modprobe_module(new_resource.module_name,
                      new_resource.module_params,
                      new_resource.timeout,
                      new_resource.verbose, true)
    end
    new_resource.updated_by_last_action(true)
  end
end
