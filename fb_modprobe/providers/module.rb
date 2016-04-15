# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
def modprobe_module(module_name, params, timeout, verbose, unload)
  verbose_flags = verbose ? '-v ' : ''
  remove_flags = unload ? '-r ' : ''
  should_run = !FB::Modprobe.module_loaded?(module_name) || unload

  params =
    if params.is_a?(Array)
      ' ' + params.join(' ')
    elsif !params
      ''
    else
      ' ' + params
    end

  # Correctly handle built-in modules. If no parameters were supplied, we just
  # return true. If the caller supplied parameters, we fail the Chef run and ask
  # them to fix their cookbook, since we can't apply them.
  if ::File.exist?("/sys/modules/#{module_name}")
    unless ::File.exist?("/sys/modules/#{module_name}/initstate")
      ::Chef::Log.warn("fb_modprobe called on built-in module '#{module_name}'")
      if params != ''
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

  execute "modprobe #{module_name}" do
    only_if { should_run }
    command '/sbin/modprobe' +
      " #{verbose_flags}#{remove_flags}#{module_name}#{params}"
    action :run
    notifies :reload, 'ohai[reload kernel]', :immediately
    timeout timeout
  end

  return should_run
end

action :load do
  updated = modprobe_module(new_resource.module_name,
                            new_resource.module_params,
                            new_resource.timeout,
                            new_resource.verbose, false)
  new_resource.updated_by_last_action(updated)
end

action :unload do
  updated = modprobe_module(new_resource.module_name,
                            new_resource.module_params,
                            new_resource.timeout,
                            new_resource.verbose, true)
  new_resource.updated_by_last_action(updated)
end
