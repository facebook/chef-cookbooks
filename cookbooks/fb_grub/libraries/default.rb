# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

module FB
  # Grub utility functions
  class Grub
    # This will extract the first root directive from the file that is
    # not a comment.
    # This isn't a very generalizable solution.
    # Grub 2 data looks like this:
    # menuentry 'CentOS (4.0.9-75_fbk14_4148_g37fe86f)' {
    #   set root='(hd0,1)'
    # or
    #   set root='hd0,gpt2'
    #
    #
    # Grub 1 data looks like this:
    # title CentOS (4.0.9-68_fbk12_4058_gd84fdb3)
    #   root (hd0,0)
    #
    # Extracted string will be in the form of 'hd0,2' regardless
    def self.extract_root_device(full_fstab)
      root_device_regexp = /^\s*[^#].*root[=\s]+['"]?\(?(\w+,\w+)\)?['"]?/
      full_fstab[root_device_regexp, 1]
    end

    def self.extract_device_hints(full_fstab)
      device_hints = []
      full_fstab.each_line do |line|
        # We don't care about any of the comments
        next if line.lstrip.start_with?('#')
        if line.lstrip.start_with?('device')
          device_hints << line.chomp
        end
      end
      device_hints
    end
  end
end
