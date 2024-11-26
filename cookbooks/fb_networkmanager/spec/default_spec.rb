#
# Cookbook:: fb_networkmanager
# Recipe:: default
#
# Copyright (c) 2020-present, Vicarious, Inc.
# Copyright (c) 2020-present, Facebook, Inc.
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

require './spec/spec_helper'
require_relative '../libraries/default'

describe FB::Networkmanager do
  let(:mock_so) do
    double('shellout')
  end

  before(:each) do
    allow(mock_so).to receive(:run_command).and_return(mock_so)
    allow(File).to receive(:exist?).with('/usr/bin/nmcli').
      and_return(true)
  end

  context '#active_connections' do
    it 'should return an empty hash if nmcli fails' do
      expect(Mixlib::ShellOut).to receive(:new).and_return(mock_so)
      allow(mock_so).to receive(:error?).and_return(true)
      expect(FB::Networkmanager.active_connections).to eq({})
    end

    it 'should return an empty hash if nmcli has no active connections' do
      expect(Mixlib::ShellOut).to receive(:new).and_return(mock_so)
      allow(mock_so).to receive(:error?).and_return(false)
      allow(mock_so).to receive(:stdout).and_return('')
      expect(FB::Networkmanager.active_connections).to eq({})
    end

    it 'should return the parsed data correctly' do
      expect(Mixlib::ShellOut).to receive(:new).and_return(mock_so)
      allow(mock_so).to receive(:error?).and_return(false)
      allow(mock_so).to receive(:stdout).and_return(
        <<~EOF,
          SomeNetwork:some-uuid:wifi:wlp2s0
          AnotherNetwork:another-uid:eth:eth0
          MyVPN:more-uuid:vpn:wlp2s0
          tun0:all-the-uids:tun:tun0
        EOF
      )
      expect(FB::Networkmanager.active_connections).to eq(
        {
          'SomeNetwork' => {
            'uuid' => 'some-uuid',
            'type' => 'wifi',
            'device' => 'wlp2s0',
          },
          'AnotherNetwork' => {
            'uuid' => 'another-uid',
            'type' => 'eth',
            'device' => 'eth0',
          },
          'MyVPN' => {
            'uuid' => 'more-uuid',
            'type' => 'vpn',
            'device' => 'wlp2s0',
          },
          'tun0' => {
            'uuid' => 'all-the-uids',
            'type' => 'tun',
            'device' => 'tun0',
          },
        },
      )
    end
  end

  # we don't test to make sure IniParse does what IniParse does,
  # instead we teste the things we're doing custom...
  context '#to_ini' do
    # this is to match how NM generates them
    it 'generates ini with no spaces around =' do
      expect(
        FB::Networkmanager.to_ini(
          {
            'section' => {
              'option' => 'value',
            },
          },
        ),
      ).to eq("[section]\noption=value\n")
    end

    it 'handles arrays as comma-separated values' do
      expect(
        FB::Networkmanager.to_ini(
          {
            'section' => {
              'option' => [
                'value1',
                'value2',
              ],
            },
          },
        ),
      ).to eq("[section]\noption=value1,value2\n")
    end
  end
end
