require './spec/spec_helper'

recipe 'fb_rpm::default', :unsupported => [:centos6, :mac_os_x] do |tc|
  let(:chef_run) do
    tc.chef_run do |node|
      node.default['shard_seed'] = 0
    end
  end

  context 'render /etc/rpm/macros' do
    it 'with empty macros' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_rpm']['macros'] = {}
      end
      expect(chef_run).to render_file('/etc/rpm/macros').
        with_content(tc.fixture('rpm_macros_empty'))
    end

    it 'with set macros' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_rpm']['macros'] = {
          '%somestuff' => 1,
          '%other_stuff' => 'some string',
          '%no_value' => nil,
        }
      end
      expect(chef_run).to render_file('/etc/rpm/macros').
        with_content(tc.fixture('rpm_macros_custom'))
    end
  end
end
