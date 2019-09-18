require './spec/spec_helper'

recipe 'fb_systemd::default', :supported => [:centos7] do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  before(:each) do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with('/run/systemd/system').
      and_return(true)
  end

  it 'should render empty config' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_systemd']['system'] = {
        'DefaultLimitNOFILE' => '666',
        'DefaultTasksAccounting' => true,
      }
    end

    expect(chef_run).to render_file('/etc/systemd/system.conf').with_content(
      tc.fixture('system.conf'),
    )
  end
end
