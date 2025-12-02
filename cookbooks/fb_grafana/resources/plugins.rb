# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
    if node['fb_grafana']['immutable_plugins'].key?(plugin) && !version.nil?
      Chef::Log.warn(
        "fb_grafana: Plugin #{plugin} is configured to be installed at " +
        "version #{version}, but #{plugin} is a built-in/immutable plugin " +
        'that cannot be managed by the user.',
      )
      next
    end

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
    next if node['fb_grafana']['plugins'].key?(plugin)
    next if node['fb_grafana']['immutable_plugins'].key?(plugin)

    execute "Uninstall grafana plugin #{plugin}" do
      command "#{basecmd} plugins uninstall #{plugin}"
    end
  end
end
