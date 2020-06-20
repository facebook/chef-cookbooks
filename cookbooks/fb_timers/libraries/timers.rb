# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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
  class Systemd
    # Path on the system where systemd units live.
    # This should be the path that `systemctl link` places the unit files at.
    UNIT_PATH = '/etc/systemd/system'.freeze

    # Sensible defaults for timer attributes.
    TIMER_DEFAULTS = {
      # name is inferred from the name within node['fb_timers']['jobs']
      # commands is required
      # calendar is required (unless one of the On... options below are set)
      'accuracy' => '1s',
      'autostart' => true,
      'command' => nil,
      'description' => nil,
      'only_if' => nil,
      'persistent' => false,
      'service_options' => {},
      'service_unit_options' => {},
      'splay' => '0s',
      'syslog' => false,
      'timeout_stop' => '90s',
      'timeout' => 'infinity',
      'timer_options' => {},
      'timer_unit_options' => {},
    }.freeze

    REQUIRED_TIMER_KEYS = ['calendar', 'commands', 'name'].freeze

    ALTERNATE_CALENDAR_KEYS = [
      'OnActiveSec',
      'OnBootSec',
      'OnStartupSec',
      'OnUnitActiveSec',
      'OnUnitInactiveSec',
    ].freeze

    TIMER_COOKBOOK_KEYS = (TIMER_DEFAULTS.keys + REQUIRED_TIMER_KEYS).freeze

    module Calendar
      def every(value = nil)
        Every.new(value)
      end

      class Every
        def initialize(value = nil)
          @value = value
        end

        # Plural generators (do take a value):

        def hours
          fail "A value is required for #{__method__}" unless @value
          fail 'A value cannot be > 24' if @value > 24
          fail 'A value cannot be <= 0' if @value <= 0
          return 'daily' if @value == 24

          "0/#{@value}:0:0"
        end

        def minutes
          fail "A value is required for #{__method__}" unless @value
          fail 'A value cannot be > 60' if @value > 60
          fail 'A value cannot be <= 0' if @value <= 0
          return 'hourly' if @value == 60

          "*:0/#{@value}:0"
        end

        # Singular generators (don't take a value):

        def weekday
          fail "A value cannot be provided for #{__method__}" if @value

          'Mon..Fri'
        end

        def week
          fail "A value cannot be provided for #{__method__}" if @value

          'weekly'
        end

        def day
          fail "A value cannot be provided for #{__method__}" if @value

          'daily'
        end

        def month
          fail "A value cannot be provided for #{__method__}" if @value

          'monthly'
        end
      end

      module_function :every
    end
  end
end
