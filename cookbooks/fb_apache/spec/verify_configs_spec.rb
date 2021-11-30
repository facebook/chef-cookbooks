require './spec/spec_helper'

recipe 'fb_apache::default', :unsupported => [:mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run(:step_into => ['fb_apache_verify_configs']) do |node|
      allow_any_instance_of(Chef::Node).to receive(:in_shard?).and_return(true)
      node.automatic['platform_family'] = 'rhel'
    end
  end

  it 'succeeds on normal run' do
    allow_any_instance_of(Mixlib::ShellOut).
      to receive(:run_command).and_return(Mixlib::ShellOut.new)
    allow_any_instance_of(Mixlib::ShellOut).
      to receive(:error?).and_return(false)

    # prepare a basic apache `conf` directory to be used during normal run
    tdir = ::Dir.mktmpdir
    ::Dir.mkdir("#{tdir}/conf")
    f = ::File.open("#{tdir}/conf/httpd.conf", 'w')
    f.write(tc.fixture('httpd.conf'))
    f.close
    allow(::Dir::Tmpname).to receive(:create).and_return(tdir)

    expect do
      chef_run.converge(described_recipe)
    end.to_not raise_error(RuntimeError)
  end
end
