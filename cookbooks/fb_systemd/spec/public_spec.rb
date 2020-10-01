# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

require_relative '../libraries/systemd_helpers.rb'

default_systemd = {
  'Service' => {
    'CapabilityBoundingSet' => ['CAP_CHOWN'],
    'Environment' => ['VAR1="def_val1"'],
    'Environment2' => ['VAR1="def_val1"'],
    'ProtectControlGroups' => 'yes',
    'SyslogIdentifier' => 'syslog1',
  },
  'Unit' => {},
  'Install' => {},
}

pruned = {
  'Service' => {
    'CapabilityBoundingSet' => ['CAP_CHOWN'],
    'Environment' => ['VAR1="def_val1"'],
    'Environment2' => ['VAR1="def_val1"'],
    'ProtectControlGroups' => 'yes',
    'SyslogIdentifier' => 'syslog1',
  },
}

override_systemd = {
  'Service' => {
    'CapabilityBoundingSet' => ['', 'CAP_SETUID'],
    'Environment' => ['VAR2="def_val2"'],
    'Environment2' => 'VAR2="def_val2"',
    'ProtectControlGroups' => 'no',
    'ProtectKernelTunables' => 'yes',
  },
}

describe FB::Systemd do
  let(:merged) { FB::Systemd.merge_unit(default_systemd, override_systemd) }

  context 'sanitize' do
    it 'returns a printable string unaltered' do
      expect(FB::Systemd.sanitize('Foo123')).to eq('Foo123')
    end

    it 'sanitizes a string with spaces' do
      expect(FB::Systemd.sanitize('Foo Bar 123')).to eq('Foo_Bar_123')
    end

    it 'sanitizes a string with non-alphanumeric characters' do
      expect(FB::Systemd.sanitize("\u2603Foo")).to eq('_Foo')
    end
  end

  context 'to_ini' do
    it 'renders a unit from a Hash' do
      expect(FB::Systemd.to_ini({
                                  'Service' => {
                                    'User' => 'nobody',
                                  },
                                })).to eq("[Service]\nUser = nobody\n")
    end

    it 'renders a unit from a String' do
      expect(FB::Systemd.to_ini("[Service]\nUser=nobody")).to eq(
        "[Service]\nUser=nobody\n",
      )
    end

    it 'renders a unit with a list' do
      expect(FB::Systemd.to_ini({
                                  'Service' => {
                                    'DisableControllers' => ['cpu', 'memory'],
                                  },
                                })).to eq(
                                  "[Service]\nDisableControllers = cpu\n" +
                                  "DisableControllers = memory\n",
                                )
    end

    it 'renders a unit with a boolean' do
      expect(FB::Systemd.to_ini({
                                  'Service' => {
                                    'PrivateNetwork' => true,
                                    'PrivateUsers' => false,
                                  },
                                })).to eq(
                                  "[Service]\nPrivateNetwork = true\n" +
                                  "PrivateUsers = false\n",
                                )
    end
  end

  context 'merge systemd unit' do
    it 'should merge when no conflict' do
      merged['Service']['SyslogIdentifier'].should eql('syslog1')
      merged['Service']['ProtectKernelTunables'].should eql('yes')
    end

    it 'should override settings' do
      merged['Service']['ProtectControlGroups'].should eql('no')
    end

    it 'should append lists together' do
      merged['Service']['Environment'].should eql(
        ['VAR1="def_val1"', 'VAR2="def_val2"'],
      )
      # A list and not a list should still be appended together
      merged['Service']['Environment2'].should eql(
        ['VAR1="def_val1"', 'VAR2="def_val2"'],
      )
    end

    it 'should handle when zeroing a list' do
      merged['Service']['CapabilityBoundingSet'].should eql(
        ['CAP_CHOWN', '', 'CAP_SETUID'],
      )
    end

    it 'should handle empty inputs' do
      FB::Systemd.merge_unit({}, {}).should eql({})
      FB::Systemd.merge_unit(default_systemd, {}).should eql(pruned)
      FB::Systemd.merge_unit({}, override_systemd).should eql(override_systemd)
    end
  end
end
