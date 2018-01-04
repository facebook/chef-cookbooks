# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
require 'shellwords'
module FB
  module Systemd
    def self.path_to_unit(path, unit_type)
      cmd = [
        '/bin/systemd-escape',
        '--path',
        "--suffix=#{unit_type}",
        path,
      ]
      s = Mixlib::ShellOut.new(cmd).run_command.stdout.chomp

      # Chef clients older than v13.3.10 have a bug in the service resource
      # https://github.com/chef/chef/pull/6230
      # so we workaround it here by calling shellescape
      if FB::Version.new(Chef::VERSION) < FB::Version.new('13.3.10')
        return s.shellescape
      else
        return s
      end
    end
  end
end
