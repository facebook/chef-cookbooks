#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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
