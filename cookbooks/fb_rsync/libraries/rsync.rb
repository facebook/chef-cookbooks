# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

module FB
  # A place for rsync helper code to live
  class Rsync
    # If 'src' starts with '::', the default rsync server is prepended to it.
    def self.determine_src(src_i, node)
      if src_i =~ /^::/
        unless node['fb_rsync']['rsync_server']
          fail 'fb_rsync: cannot build command as neither rsync_server ' +
            'nor source are set.'
        end
        src = "#{node['fb_rsync']['rsync_server']}#{src_i}"
      else
        src = src_i
      end
      src
    end

    # Returns an rsync commandline.
    def self.cmd(node, src_i, rest)
      src = determine_src(src_i, node)

      return [node['fb_rsync']['rsync_command'], src, rest].join(' ')
    end

    # Custom error class for easier monitoring of delete failures
    class MaxDeleteLimit < RuntimeError; end
  end
end
