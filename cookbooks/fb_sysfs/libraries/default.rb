#
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
  class Sysfs
    def self.check(current, new, type)
      case type
      when :list
        current.include?("[#{new}]")
      when :int
        current.to_i == new.to_i
      else
        current.chomp == new.chomp
      end
    end
  end
end
