# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
module FB
  module Systemd
    def self.path_to_unit(path, unit_type)
      cmd = [
        '/bin/systemd-escape',
        '--path',
        "--suffix=#{unit_type}",
        path,
      ]
      return Mixlib::ShellOut.new(cmd).run_command.stdout.chomp
    end
  end
end
