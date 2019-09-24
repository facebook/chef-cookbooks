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
    # Internal helper function to generate /etc/apt.conf entries
    def self._gen_apt_conf_entry(k, v, i = 0)
      indent = ' ' * i
      if v.is_a?(Hash)
        s = "\n#{indent}#{k} {"
        v.each do |kk, vv|
          s += self._gen_apt_conf_entry(kk, vv, i + 2)
        end
        s += "\n#{indent}};"
        return s
      elsif v.is_a?(Array)
        s = ''
        v.each do |vv|
          s += self._gen_apt_conf_entry(k, vv, i)
        end
        return s
      elsif v.is_a?(TrueClass)
        return "\n#{indent}#{k} \"true\";"
      elsif v.is_a?(FalseClass)
        return "\n#{indent}#{k} \"false\";"
      else
        return "\n#{indent}#{k} \"#{v}\";"
      end
    end

    # Grab all keyrings owned by a package. We do not include
    def self._get_owned_keyring_files(node)
      Dir.glob('/etc/apt/trusted.gpg.d/*').select do |keyring|
        cmd = dpkg("-S #{keyring}")
        # reject this file if it isn't in a package...
        next false if cmd.error?

        # if it is in a package, double check it's not been modified
        pkg = cmd.stdout.lines.first.split(':').first
        cmd = dpkg("-V #{pkg}")
        modified_files = cmd.stdout.lines.map { |line| line.split.last }
        if modified_files.include?(keyring)
          if node['fb_apt']['allow_modified_pkg_keyrings']
            Chef::Log.warn(
              "fb_apt[keys]: #{keyring} has been modified but we are still " +
              'trusting it, do to ' +
              'node["fb_apt"]["allow_modified_pkg_keyrings"]',
            )
          else
            fail "fb_apt[keys]: keyring #{keyring} would be trusted, but " +
              "has been modified since package (#{pkg}) was installed."
          end
        end

        # OK, then we can accept this file
        true
      end
    end

    def self._run(cmd, arg)
      Mixlib::ShellOut.new("LANC=C #{cmd} #{arg}").run_command
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

    # Here ye here ye, read this before touching keys!
    #
    # On modern debian and ubuntu, all keys are stored in files in
    # `/etc/apt/trusted.gpg.d/`, and **never** on `/etc/apt/trusted.gpg`,
    # this we can know what the Distro keys are by reading all keys in
    # all keyring files owned by packages. So what's what we populate
    # the default list with.
    #
    # However, for Ubuntu <= 16.04 they are on the `/etc/apt/trusted.gpg` list,
    # so we hard-code those, the distros are old enough they won't change.
    def self.get_official_keyids(node)
      if node.ubuntu? && node['platform_version'].to_i <= 16
        return %w{
          40976EAF437D05B5
          46181433FBB75451
          3B4FE6ACC0B21F32
          D94AA3F0EFE21092
          0BFB847F3F272F5B
        }
      end
      keyids = _extract_keyids(_get_owned_keyring_files(node))
      Chef::Log.debug("fb_apt[keys]: Official keyids: #{keyids}")
      keyids
    end

    def self.get_installed_keyids(node)
      rings = _get_owned_keyring_files(node)
      rings << '/etc/apt/trusted.gpg'
      _extract_keyids(rings)
    end
  end
end
