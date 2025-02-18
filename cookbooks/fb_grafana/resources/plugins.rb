default_action :manage

action_class do
  include FB::Grafana::Provider
end

action :manage do
  installed = load_current_plugins
  available = load_available_plugins
  plugin_dir = node['fb_grafana']['config']['paths']['plugins'] ||
    '/var/lib/grafana/plugins'
  basecmd = "grafana-cli --pluginsDir #{plugin_dir}"
  node['fb_grafana']['plugins'].each do |plugin, version|
    # If a version is specified, see if it's installed and on that version...
    if version && installed[plugin] == version
      Chef::Log.debug(
        "fb_grafana_plugins[#{plugin}]: version #{version} already " +
        'installed, nothing to do',
      )
      next
    # If a version is not specificed, see if it's installed and up-to-date
    elsif !version && installed[plugin] &&
          installed[plugin] == available[plugin]
      Chef::Log.debug(
        "fb_grafana_plugins[#{plugin}]: latest version already " +
        'installed, nothing to do',
      )
      next
    end
    to_install = version || available[plugin]
    Chef::Log.debug(
      "fb_grafana_plugins[#{plugin}]: Installing version " +
      "#{to_install} (was #{installed[plugin]})",
    )
    # In theory removing the old version should not be necessary
    # but not all plugins will upgrade. For example, see
    # https://github.com/grafana/grafana-polystat-panel/issues/151#issuecomment-682283406
    if installed[plugin]
      execute "Uninstalling grafana plugin #{plugin}" do
        command "#{basecmd} plugins uninstall #{plugin}"
      end
    end
    execute "Install grafana plugin #{plugin}" do
      command "#{basecmd} plugins install #{plugin} #{to_install}"
    end
  end

  Dir.glob("#{plugin_dir}/*").each do |pluginpath|
    plugin = ::File.basename(pluginpath)
    # NOTE WELL: Cannot use ruby-style
    #    if node['fb_grafana']['plugins'][plugin]
    # because the value can be nil, which evaluates to false!
    next if node['fb_grafana']['plugins'].include?(plugin)

    execute "Uninstall grafana plugin #{plugin}" do
      command "#{basecmd} plugins uninstall #{plugin}"
    end
  end
end
