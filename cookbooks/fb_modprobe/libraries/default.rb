# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
module FB
  # add kmod related functions previously in fb_hardware
  class Modprobe
    def self.supports_ipv6_autoconf_param?
      cmd = '/sbin/modinfo ipv6 | /bin/grep -q autoconf:'
      return Mixlib::ShellOut.new(cmd).run_command.exitstatus.zero?
    end

    def self.module_loaded?(loaded_mod)
      # modprobe handles both, but /proc/modules only uses underscores
      loaded_mod.tr!('-', '_')

      # Handle built-in modules correctly
      return File.exist?("/sys/module/#{loaded_mod}")
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
      return false
    end
  end
end
