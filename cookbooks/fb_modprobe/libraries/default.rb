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
  # add kmod related functions previously in fb_hardware
  class Modprobe
    def self.module_version(loaded_mod)
      loaded_mod.tr!('-', '_')
      version_file = "/sys/module/#{loaded_mod}/version"

      if File.exist?(version_file)
        return IO.read(version_file).strip
      end

      nil
    end

    def self.module_refcnt(loaded_mod)
      loaded_mod.tr!('-', '_')
      version_file = "/sys/module/#{loaded_mod}/refcnt"

      if File.exist?(version_file)
        return IO.read(version_file).strip
      end

      nil
    end

    def self.supports_ipv6_autoconf_param?
      cmd = '/sbin/modinfo ipv6 | /bin/grep -q autoconf:'
      Mixlib::ShellOut.new(cmd).run_command.exitstatus.zero?
    end

    def self.module_loaded?(loaded_mod)
      # modprobe handles both, but /proc/modules only uses underscores
      loaded_mod.tr!('-', '_')

      # Handle built-in modules correctly
      File.exist?("/sys/module/#{loaded_mod}")
    end

    # This is a significantly better test to see if a module is usable
    def self.module_initialized?(loaded_mod)
      loaded_mod.tr!('-', '_')
      initstate_path = "/sys/module/#{loaded_mod}/initstate"
      if File.exist?(initstate_path)
        initstate = IO.read(initstate_path)
        return initstate.strip == 'live'
      elsif File.exist?("/sys/module/#{loaded_mod}")
        # Modules that are built-in don't have the initstate file. Since they're
        # built-in, the fact that Chef is running means the MODULE_INIT function
        # must have completed, otherwise we would hang forever at boot.
        return true
      end
      false
    end
  end
end
