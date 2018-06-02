#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require_relative '../libraries/default'

describe FB::Sysfs::Provider do
  include FB::Sysfs::Provider

  context '#check' do
    it 'should handle lists' do
      expect(check("[one] two three\n", 'one', :list)).to eq(true)
      expect(check("one [two] three\n", 'one', :list)).to eq(false)
      expect(check("one [two] three\n", 'two', :list)).to eq(true)
      expect(check("one [two] three\n", 'three', :list)).to eq(false)
      expect(check("one [two] three\n", 'oogabooga', :list)).to eq(false)
    end

    it 'should handle strings' do
      expect(check('one', 'one', :string)).to eq(true)
      expect(check("one\n", 'one', :string)).to eq(true)
      expect(check("onee\n", 'one', :string)).to eq(false)
      expect(check("two\n", 'one', :string)).to eq(false)
    end

    it 'should handle integers' do
      expect(check(1, '1', :int)).to eq(true)
      expect(check('1', '1', :int)).to eq(true)
      expect(check(1, 1, :int)).to eq(true)
      expect(check('1', 1, :int)).to eq(true)
      expect(check("1\n", 1, :int)).to eq(true)
      expect(check("1\n", '1', :int)).to eq(true)

      expect(check(1, '2', :int)).to eq(false)
      expect(check('1', '2', :int)).to eq(false)
      expect(check(1, 2, :int)).to eq(false)
      expect(check('1', 2, :int)).to eq(false)
      expect(check("1\n", 2, :int)).to eq(false)
      expect(check("1\n", '2', :int)).to eq(false)
    end
  end
end
