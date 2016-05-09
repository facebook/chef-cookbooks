# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
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
  end
end
