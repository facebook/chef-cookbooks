# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

require './spec/spec_helper'

def mock_lsblk(rota)
  so = double('lsblk')
  so.should_receive(:run_command).and_return(so)
  so.should_receive(:error!).and_return(nil)
  so.should_receive(:stdout).and_return(
    "{\"blockdevices\": [{\"rota\": \"#{rota}\"}]}",
  )
  Mixlib::ShellOut.should_receive(:new).with(
    'lsblk --json --output ROTA /dev/blocka42',
  ).and_return(so)
end
