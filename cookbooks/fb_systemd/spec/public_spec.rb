# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require_relative '../libraries/systemd_helpers.rb'

describe FB::Systemd do
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

    it' renders a unit with a boolean' do
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
end
