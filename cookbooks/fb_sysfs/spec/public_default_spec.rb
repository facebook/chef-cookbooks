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
include FB::Sysfs

describe FB::Sysfs do
  context '#check' do
    it 'should handle lists' do
      FB::Sysfs.check("[one] two three\n", 'one', :list).should eq(true)
      FB::Sysfs.check("one [two] three\n", 'one', :list).should eq(false)
      FB::Sysfs.check("one [two] three\n", 'two', :list).should eq(true)
      FB::Sysfs.check("one [two] three\n", 'three', :list).should eq(false)
      FB::Sysfs.check("one [two] three\n", 'oogabooga', :list).should eq(false)
    end

    it 'should handle strings' do
      FB::Sysfs.check('one', 'one', :string).should eq(true)
      FB::Sysfs.check("one\n", 'one', :string).should eq(true)
      FB::Sysfs.check("onee\n", 'one', :string).should eq(false)
      FB::Sysfs.check("two\n", 'one', :string).should eq(false)
    end

    it 'should handle integers' do
      FB::Sysfs.check(1, '1', :int).should eq(true)
      FB::Sysfs.check('1', '1', :int).should eq(true)
      FB::Sysfs.check(1, 1, :int).should eq(true)
      FB::Sysfs.check('1', 1, :int).should eq(true)
      FB::Sysfs.check("1\n", 1, :int).should eq(true)
      FB::Sysfs.check("1\n", '1', :int).should eq(true)

      FB::Sysfs.check(1, '2', :int).should eq(false)
      FB::Sysfs.check('1', '2', :int).should eq(false)
      FB::Sysfs.check(1, 2, :int).should eq(false)
      FB::Sysfs.check('1', 2, :int).should eq(false)
      FB::Sysfs.check("1\n", 2, :int).should eq(false)
      FB::Sysfs.check("1\n", '2', :int).should eq(false)
    end
  end
end
