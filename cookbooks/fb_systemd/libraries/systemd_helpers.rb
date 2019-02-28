# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require 'iniparse'
require 'shellwords'

module FB
  class Systemd
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

    def self.sanitize(name)
      name.gsub(/[^[a-zA-Z0-9]]/, '_')
    end

    # this is based on
    # https://github.com/chef/chef/blob/61a8aa44ac33fc3bbeb21fa33acf919a97272eb7/lib/chef/resource/systemd_unit.rb#L66-L83
    def self.to_ini(content)
      case content
      when Hash
        IniParse.gen do |doc|
          content.each_pair do |sect, opts|
            doc.section(sect) do |section|
              opts.each_pair do |opt, val|
                [val].flatten.each do |v|
                  section.option(opt, v)
                end
              end
            end
          end
        end.to_s
      else
        IniParse.parse(content.to_s).to_s
      end
    end
  end
end
