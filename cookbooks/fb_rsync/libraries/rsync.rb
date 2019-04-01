# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

      [node['fb_rsync']['rsync_command'], src, rest].join(' ')
    end

    # Custom error class for easier monitoring of delete failures
    class MaxDeleteLimit < RuntimeError; end
  end
end
