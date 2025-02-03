# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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

module FB
  # APT utility functions
  class Apt
    TRUSTED_D = '/etc/apt/trusted.gpg.d'.freeze
    PEM_D = "#{Chef::Config[:file_cache_path]}/fb_apt_pems".freeze

    # Internal helper function to generate /etc/apt.conf entries
    def self._gen_apt_conf_entry(k, v, i = 0)
      indent = ' ' * i
      case v
      when Hash
        s = "\n#{indent}#{k} {"
        v.each do |kk, vv|
          s += self._gen_apt_conf_entry(kk, vv, i + 2)
        end
        s += "\n#{indent}};"
        return s
      when Array
        s = ''
        v.each do |vv|
          s += self._gen_apt_conf_entry(k, vv, i)
        end
        return s
      when TrueClass
        return "\n#{indent}#{k} \"true\";"
      when FalseClass
        return "\n#{indent}#{k} \"false\";"
      else
        return "\n#{indent}#{k} \"#{v}\";"
      end
    end

    # Grab all keyrings owned by a package. We do not include
    def self._get_owned_keyring_files(node)
      s = dpkg('-S /etc/apt/trusted.gpg.d/*')
      # owned keys are on stdout, unowned keys are on stderr
      owned_keys = Set.new
      packages = []
      s.stdout.each_line do |line|
        package, file = line.strip.split(': ')
        # dpkg reports on all files that WOULD match the path, even
        # if they don't exist. Skip ones that have been removed
        next unless ::File.exist?(file)

        owned_keys.add(file)
        packages << package
      end
      Chef::Log.debug("fb_apt[keys]: Owned keys: #{owned_keys}")
      packages.each do |pkg|
        cmd = dpkg("-V #{pkg}")
        modified_files =
          Set.new(cmd.stdout.lines.map { |line| line.split.last })
        # keys that in both sets are modified keys
        modified_keys = owned_keys & modified_files
        Chef::Log.debug(
          "fb_apt[keys]: Modified keys from #{pkg}: #{modified_keys}",
        )
        unless modified_keys.empty?
          if node['fb_apt']['allow_modified_pkg_keyrings']
            Chef::Log.warn(
              'fb_apt[keys]: The following keys have been modified but we ' +
              'are still trusting it, due to ' +
              'node["fb_apt"]["allow_modified_pkg_keyrings"]: ' +
              modified_keys.to_a.join(', '),
            )
          else
            fail 'fb_apt[keys]: The following keyrings would be trusted, but ' +
              "has been modified since package (#{pkg}) was installed: " +
              modified_keys.to_a.join(', ')
          end
        end
      end
      owned_keys.to_a
    end

    def self._run(cmd, arg)
      Mixlib::ShellOut.new("LANG=C #{cmd} #{arg}").run_command
    end

    def self.dpkg(arg)
      _run('dpkg', arg)
    end

    def self.aptkey(arg)
      _run('apt-key', arg)
    end

    def self._extract_keyids(rings)
      rings.map do |keyring|
        cmd = aptkey("--keyring #{keyring} finger --keyid-format long")
        cmd.error!
        ids = cmd.stdout.lines.map do |line|
          next unless line.start_with?('pub ')

          line.split[1].split('/')[1]
        end.compact
        Chef::Log.debug(
          "fb_apt[keys]: Keyids from #{keyring}: #{ids.join(', ')}",
        )
        ids
      end.flatten
    end

    def self.get_legacy_keyids
      _extract_keyids(['/etc/apt/trusted.gpg'])
    end

    def self.determine_base_repo_components(node)
      components = %w{main}
      if node.ubuntu?
        components << 'universe'
      end

      if node['fb_apt']['want_non_free']
        if node.debian?
          components += %w{contrib non-free non-free-firmware}
        elsif node.ubuntu?
          components += %w{restricted multiverse}
        else
          fail "Don't know how to setup non-free for #{node['platform']}"
        end
      end

      components
    end

    def self.base_sources(node)
      base_repos = {}
      sources = {}
      mirror = node['fb_apt']['mirror']
      security_mirror = node['fb_apt']['security_mirror']
      # By default, we want our current distro to assemble to repo URLs.
      # However, for when people want to upgrade across distros, we let
      # them specify a distro to upgrade to.
      distro = node['fb_apt']['distro'] || node['lsb']['codename']

      # only add base repos if mirror is set and codename is available
      if mirror && distro
        components = FB::Apt.determine_base_repo_components(node)

        base_repos['base'] = {
          'url' => mirror,
          'suite' => distro,
        }

        # Security updates
        pv = node['platform_version'].to_i
        if node.debian? && distro != 'sid' && pv != 0 && pv > 9
          # In buster/10 and before the suite was ${distro}/updates
          # After that it became ${distro}-security
          suite = pv == 10 ? "#{distro}/updates" : "#{distro}-security"
          base_repos['security'] = {
            'url' => "#{security_mirror}debian-security",
            'suite' => suite,
          }
        elsif node.ubuntu?
          base_repos['security'] = {
            'url' => security_mirror,
            'suite' => "#{distro}-security",
          }
        end

        # Debian Sid doesn't have updates or backports
        unless node.debian? && distro == 'sid'
          # Stable updates
          base_repos['updates'] = {
            'url' => mirror,
            'suite' => "#{distro}-updates",
          }

          if node['fb_apt']['want_backports']
            base_repos['backports'] = {
              'url' => mirror,
              'suite' => "#{distro}-backports",
            }
          end
        end

        base_keyring = node.debian? ?
          '/usr/share/keyrings/debian-archive-keyring.gpg' :
          '/usr/share/keyrings/ubuntu-archive-keyring.gpg'
        base_repos.each do |name, config|
          config.merge!({
                          'options' => {
                            'signed-by' => base_keyring,
                          },
            'components' => components,
            'type' => 'deb',
                        })
          sources[name] = config
          if node['fb_apt']['want_source']
            source["#{name}_src"] = config.merge({ 'type' => 'deb-src' })
          end
        end
      end
      sources
    end

    def self.gen_sources_line(config)
      type = config['type'] || 'deb'
      options = config['options'].dup || {}
      if config['key']
        options['signed-by'] = keyring_path_from_name(config['key'])
      end
      c_str = config['components'].join(' ')
      options_str = ''
      unless options.empty?
        options_str = "[#{options.map { |k, v| "#{k}=#{v}" }.join(' ')}] "
      end
      "#{type} #{options_str}#{config['url']} #{config['suite']} #{c_str}"
    end

    def self.pem_path_from_name(name)
      "#{PEM_D}/#{name}.asc"
    end

    def self.keyring_path_from_name(name)
      "#{TRUSTED_D}/#{name}.gpg"
    end
  end
end
