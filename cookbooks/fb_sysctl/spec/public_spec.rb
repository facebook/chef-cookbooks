# Copyright (c) 2018-present, Facebook, Inc.

require 'chef/node'
require_relative '../libraries/sync'

describe FB::Sysctl do
  let(:node) { Chef::Node.new }

  context '#binary_path' do
    it 'returns linux path' do
      allow(node).to receive(:macos?).and_return(false)
      expect(FB::Sysctl.binary_path(node)).to eq('/sbin/sysctl')
    end

    it 'returns macos path' do
      allow(node).to receive(:macos?).and_return(true)
      expect(FB::Sysctl.binary_path(node)).to eq('/usr/sbin/sysctl')
    end
  end

  context '#normalize' do
    it 'handles spaces' do
      expect(FB::Sysctl.normalize('1 2 3')).to eq('1 2 3')
    end

    it 'handles tabs' do
      expect(FB::Sysctl.normalize("1\t2\t3")).to eq('1 2 3')
    end
  end

  context '#current_settings' do
    let(:shellout) do
      double(
        :run_command => nil,
        :error! => nil,
        :stdout => '',
        :stderr => '',
        :exitstatus => 0,
        :live_stream => '',
      )
    end

    it 'handles linux format' do
      allow(node).to receive(:macos?).and_return(false)
      allow(shellout).to receive(:stdout).
        and_return("fake1.sysctl.setting=1\nfake2.sysctl.setting=2")
      allow(Mixlib::ShellOut).to receive(:new).with('/sbin/sysctl -a').
        and_return(shellout)
      allow(shellout).to receive(:run_command).and_return(shellout)
      allow(shellout).to receive(:error?).and_return(false)
      expect(FB::Sysctl.current_settings(node)).to eq(
        {
          'fake1.sysctl.setting' => '1',
          'fake2.sysctl.setting' => '2',
        },
      )
    end

    it 'handles macos format' do
      allow(node).to receive(:macos?).and_return(true)
      allow(shellout).to receive(:stdout).
        and_return("fake1.sysctl.setting = 1\nfake2.sysctl.setting = 2")
      allow(Mixlib::ShellOut).to receive(:new).with('/usr/sbin/sysctl -a').
        and_return(shellout)
      allow(shellout).to receive(:run_command).and_return(shellout)
      allow(shellout).to receive(:error?).and_return(false)
      expect(FB::Sysctl.current_settings(node)).to eq(
        {
          'fake1.sysctl.setting' => '1',
          'fake2.sysctl.setting' => '2',
        },
      )
    end
  end

  context '#incorrect_settings' do
    it 'treats identical settings as the same' do
      expect(
        FB::Sysctl.incorrect_settings(
          { 'somekey' => '1 2 val thing' },
          { 'somekey' => '1 2 val thing' },
        ),
      ).to eq({})
    end

    it 'treats settings with whitespace differences the same' do
      expect(
        FB::Sysctl.incorrect_settings(
          { 'somekey' => '1  2    val thing' },
          { 'somekey' => '1 2 val thing' },
        ),
      ).to eq({})
    end

    it 'treats different settings as different' do
      expect(
        FB::Sysctl.incorrect_settings(
          { 'somekey' => '1 3 val thing' },
          { 'somekey' => '1 2 val thing' },
        ),
      ).to eq({ 'somekey' => '1 3 val thing' })
    end

    it 'handles integers and strings correctly' do
      expect(
        FB::Sysctl.incorrect_settings(
          { 'somekey' => 12 },
          { 'somekey' => '12' },
        ),
      ).to eq({})
    end

    it 'handles many values properly' do
      current = {
        'somekey' => 'value',
        'somekey2' => 'another_value',
        'somekey3' => 'crazy val 2 you',
        'somekey4' => '[stuff] here',
        'somekey5' => 123123,
        'somekey6' => 121209,
      }
      desired = current.dup
      desired['somekey2'] = 'differnt val'
      desired['somekey4'] = 'poop'
      desired['somekey6'] = 99
      expect(
        FB::Sysctl.incorrect_settings(
          current,
          desired,
        ),
      ).to eq(
        {
          'somekey2' => 'another_value',
          'somekey4' => '[stuff] here',
          'somekey6' => '121209',
        },
      )
    end

    it 'fails on non-existent keys' do
      expect do
        FB::Sysctl.incorrect_settings(
          { 'real_key' => 'val' },
          { 'not_real_key' => 'val2' },
        )
      end.to raise_error(RuntimeError)
    end

    it 'ignores keys we do not care about' do
      expect(
        FB::Sysctl.incorrect_settings(
          { 'real_key' => 'val', 'extra_key' => 'val2' },
          { 'real_key' => 'val' },
        ),
      ).to eq({})
    end
  end
end
