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
  module Systemd
    # Path on the system where systemd units live.
    # This should be the path that `systemctl link` places the unit files at.
    UNIT_PATH = '/etc/systemd/system'.freeze

    # Sensible defaults for timer attributes.
    TIMER_DEFAULTS = {
      # name is inferred from the name within node['fb_timers']['jobs']
      # command is required
      # calendar is required
      'timeout' => '0s',
      'accuracy' => '1s',
      'persistent' => false,
      'splay' => '0s',
      'only_if' => nil,
      'syslog' => false,
      'service_options' => {},
      'service_unit_options' => {},
      'timer_options' => {},
      'autostart' => true,
    }.freeze

    module Calendar
      def every(value = nil)
        return Every.new(value)
      end

      class Every
        def initialize(value = nil)
          @value = value
        end

        # Plural generators (do take a value):

        def hours
          fail "A value is required for #{__method__}" unless @value
          return "0/#{@value}:0:0"
        end

        def minutes
          fail "A value is required for #{__method__}" unless @value
          return "*:0/#{@value}:0"
        end

        # Singular generators (don't take a value):

        def weekday
          fail "A value cannot be provided for #{__method__}" if @value
          return 'Mon..Fri'
        end

        def week
          fail "A value cannot be provided for #{__method__}" if @value
          return 'weekly'
        end

        def day
          fail "A value cannot be provided for #{__method__}" if @value
          return 'daily'
        end

        def month
          fail "A value cannot be provided for #{__method__}" if @value
          return 'monthly'
        end
      end

      module_function :every
    end
  end
end
