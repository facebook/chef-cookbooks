# Copyright (c) 2019-present, Facebook, Inc.
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
  module Grubby
    def self.default_kernel
      @default_kernel ||= begin
        res = shell_out('/usr/sbin/grubby --default-kernel')
        return [] if res.error?
        res.stdout.strip
      end
    end

    def self.kernels
      @kernels ||= begin
        ::Dir.glob('/boot/vmlinuz-*-*.*.*').sort
      end
    end

    def get_boot_entry(kernel_path)
      @boot_entries ||= {}
      @boot_entries[kernel_path] ||= begin
        res = shell_out("/usr/sbin/grubby --info=#{kernel_path}")
        return {} if res.error?
        res.stdout.lines.map(&:strip).
          map { |line| line.split('=', 2) }.to_h.
          map do |key, val|
            val.start_with?('"') ? [key, val[1..-2]] : [key, val.to_i]
          end.
          to_h
      end
    end

    def get_add_args(boot_args, include_args)
      # only the arguments that need to be included that are
      # not already in boot_args
      include_args - boot_args
    end

    def get_boot_args(kernel_path)
      @boot_args ||= {}
      @boot_args[kernel_path] ||=
        get_boot_entry(kernel_path)['args'].split.to_set
    end

    def get_rm_args(boot_args, exclude_args)
      # only the arguments that need to be excluded that are
      # currently in boot_args
      exclude_args & boot_args
    end

    def update_grub_cmd(kernel_path, add_args, rm_args)
      cmd = ['/usr/sbin/grubby', '--update-kernel', kernel_path]
      unless add_args.empty?
        cmd << "--args=#{add_args.to_a.join(' ')}"
      end
      unless rm_args.empty?
        cmd << "--remove-args=#{rm_args.to_a.join(' ')}"
      end
      return cmd
    end
  end
end
