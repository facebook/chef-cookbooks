# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

module FB
  module Timers
    # Take a list of systemd units, and gather up their status in a single
    # class to systemctl, returning a hash
    def self.get_systemd_unit_status(units)
      systemctl_show = 'systemctl show -p Id -p UnitFileState -p ActiveState'
      systemctl_show = "#{systemctl_show} #{units.join(' ')}"
      so = Mixlib::ShellOut.new(systemctl_show).run_command
      fail 'fb_timers: systemctl shellout failed!' if so.exitstatus != 0
      stdout = so.stdout
      # Get rid of empty lines
      stdout = stdout.split("\n").reject(&:empty?)
      if stdout.size % 3 != 0
        fail 'fb_timers: unexpected output from systemctl unit status'
      end
      unit_status_map = {}
      # Take three lines at a time, and create a hash entry for each keyed on
      # unit id
      until stdout.empty?
        unit_status = stdout.pop(3)
        id, active, unitfile = unit_status.map { |x| x.split('=')[1].to_s }
        unit_status_map[id] = { :Active => active, :UnitFileState => unitfile }
      end
      unit_status_map
    end
  end
end
