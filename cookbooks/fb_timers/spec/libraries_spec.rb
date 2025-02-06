require './spec/spec_helper'
require_relative '../libraries/default'

expected_service = {
  # A service which is already active and enabled
  'a.service' => {
    :Active => 'active',
    :UnitFileState => 'enabled',
  },
  # A service systemd doesn't know about
  'b.service' => {
    :Active => 'inactive',
    :UnitFileState => '',
  },
}

expected_timer = {
  # A timer which is already active and enabled
  'a.timer' => {
    :Active => 'active',
    :UnitFileState => 'enabled',
  },
  # A timer systemd doesn't know about
  'b.timer' => {
    :Active => 'inactive',
    :UnitFileState => '',
  },
}

service_list = ['a', 'b']
service_list_with_type = ['a.service', 'b.service']
systemctl_service_stdout = "Id=a.service\nActiveState=active\nUnitFileState" +
  "=enabled\n\nId=b.service\nActiveState=inactive\nUnitFileState=\n"

timer_list = ['a', 'b']
timer_list_with_type = ['a.timer', 'b.timer']
systemctl_timer_stdout = "Id=a.timer\nActiveState=active\nUnitFileState" +
  "=enabled\n\nId=b.timer\nActiveState=inactive\nUnitFileState=\n"

describe FB::Timers do
  context 'get_systemd_unit_status' do
    it 'should build the correct service status hash' do
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).
        and_return(double('shellout', :stdout => systemctl_service_stdout, :exitstatus => 0))
      service_status = FB::Timers.get_systemd_unit_status(service_list)
      service_status.should eql(expected_service)
      # If unit type is specified
      service_status = FB::Timers.get_systemd_unit_status(service_list_with_type)
      service_status.should eql(expected_service)
    end

    it 'should build the correct timer status hash' do
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).
        and_return(double('shellout', :stdout => systemctl_timer_stdout, :exitstatus => 0))
      timer_status = FB::Timers.get_systemd_unit_status(timer_list)
      timer_status.should eql(expected_timer)
      # If unit type is specified
      timer_status = FB::Timers.get_systemd_unit_status(timer_list_with_type)
      timer_status.should eql(expected_timer)
    end

    it 'should fail when the systemctl shellout returns non zero' do
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).
        and_return(double('shellout', :stdout => '', :exitstatus => 1))
      expect do
        FB::Timers.get_systemd_unit_status(service_list)
      end.to raise_error(
        RuntimeError, /fb_timers: systemctl shellout failed!/
      )
    end

    it 'should fail when unexpected stdout encountered' do
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).
        and_return(double('shellout', :stdout => 'wut', :exitstatus => 0))
      expect do
        FB::Timers.get_systemd_unit_status(service_list)
      end.to raise_error(
        RuntimeError, /fb_timers: unexpected output from systemctl unit status/
      )
    end
  end
end
