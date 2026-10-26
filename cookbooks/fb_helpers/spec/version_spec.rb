# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
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

require_relative '../libraries/fb_helpers'

describe FB::Version do
  it 'parses basic version' do
    expect(FB::Version.new('1.3').to_a).to eq([1, 3])
  end

  # rubocop:disable Lint/UselessComparison,Style/CaseEquality
  # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
  context 'compares versions' do
    it 'less than' do
      expect(FB::Version.new('1.3') < FB::Version.new('1.21')).to eq(true)
      expect(FB::Version.new('1.3') < FB::Version.new('1.2')).to eq(false)
      expect(FB::Version.new('1.3') < FB::Version.new('1.3')).to eq(false)
    end
    it 'less than or equal' do
      expect(FB::Version.new('3.3.4') <= FB::Version.new('4.5')).to eq(true)
      expect(FB::Version.new('3.3.4') <= FB::Version.new('3.3.4')).to eq(true)
      expect(FB::Version.new('3.3.4') <= FB::Version.new('1.2')).to eq(false)
    end
    it 'greater than' do
      expect(FB::Version.new('3.3.10') > FB::Version.new('3.4')).to eq(false)
      expect(FB::Version.new('3.3.10') > FB::Version.new('3.3.10')).to eq(false)
      expect(FB::Version.new('3.3.10') > FB::Version.new('3.2')).to eq(true)
    end
    it 'greater than or equal' do
      expect(FB::Version.new('10.2') >= FB::Version.new('10.2.3')).to eq(false)
      expect(FB::Version.new('10.2') >= FB::Version.new('10.2')).to eq(true)
      expect(FB::Version.new('10.2') >= FB::Version.new('10.1.2')).to eq(true)
    end
    it 'equal' do
      expect(FB::Version.new('1.2.6') == FB::Version.new('1.2.7')).to eq(false)
      expect(FB::Version.new('1.2.6') == FB::Version.new('1.2.6')).to eq(true)
      expect(FB::Version.new('1.2.6') == FB::Version.new('1.2.5')).to eq(false)
    end
    it 'compare' do
      expect(FB::Version.new('1.2.36') <=> FB::Version.new('1.2.37')).to eq(-1)
      expect(FB::Version.new('1.2.36') <=> FB::Version.new('1.2.36')).to eq(0)
      expect(FB::Version.new('1.2.36') <=> FB::Version.new('1.2.35')).to eq(1)
    end
    it 'three equals' do
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.2.37')).
        to eq(false)
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.2.36')).
        to eq(true)
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.2.35')).
        to eq(false)
    end
    it 'three equals loose matching' do
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.1')).to eq(false)
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.2')).to eq(true)
      expect(FB::Version.new('1.2.36') === FB::Version.new('1.4.35')).
        to eq(false)
    end
  end
  # rubocop:enable Lint/UselessComparison,Style/CaseEquality
  # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands
  context 'old behavior' do
    context 'broken' do
      it 'ignores _' do
        # '1_2'.to_i == 12, as it's used for things like 1_000_000
        expect(FB::Version.new('1_2.6') <=> FB::Version.new('1.2.7')).to eq(-1)
      end
      it 'ignores anything after -' do
        expect(FB::Version.new('1-2.6') <=> FB::Version.new('1-1.6')).to eq(1)
        expect(
          FB::Version.new('5.6.9-90_fbk1') <=> FB::Version.new('5.6.9-91_fbk2'),
        ).to eq(-1)
      end
    end
    context 'actually OK' do
      it 'ignores _' do
        # '1_2'.to_i == 12, as it's used for things like 1_000_000
        expect(FB::Version.new('1_2.6') <=> FB::Version.new('1_2.7')).to eq(-1)
        expect(FB::Version.new('1_2.6') <=> FB::Version.new('1_2.5')).to eq(1)
      end
      it 'ignores anything after -' do
        expect(FB::Version.new('1-2.6') <=> FB::Version.new('2-1.1')).to eq(-1)
      end
    end
  end
end

describe FB::RpmVersion do
  def rv(s)
    FB::RpmVersion.new(s)
  end

  # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands,Style/CaseEquality
  it 'compares version before release' do
    expect(rv('0.7-2') <=> rv('0.7.1-1')).to eq(-1)
    expect(rv('0.7-2.el10_4') <=> rv('0.7.1-1.el10_4')).to eq(-1)
    expect(rv('0.7-2.hsx.el9') <=> rv('0.7.1-1.hsx.el9')).to eq(-1)
    expect(rv('0.7.1-1') > rv('0.7-2')).to eq(true)
  end

  it 'compares releases when versions match' do
    expect(rv('6.9.0-0_fbk2') <=> rv('6.9.0-0_fbk3')).to eq(-1)
    expect(rv('3.6.8-56.el8_10.0') <=> rv('3.6.8-51.el8_9.2')).to eq(1)
  end

  it 'sorts a missing release before any release' do
    expect(rv('1.0') <=> rv('1.0-1')).to eq(-1)
    expect(rv('1.0-') <=> rv('1.0')).to eq(0)
  end

  it 'handles epochs' do
    expect(rv('1:1.0') <=> rv('2.0')).to eq(1)
    expect(rv('0:1.0') <=> rv('1.0')).to eq(0)
  end

  it 'ignores leading zeros' do
    expect(rv('1.0') <=> rv('1.00')).to eq(0)
    expect(rv('550.90.07') <=> rv('550.90.7')).to eq(0)
  end

  it 'handles alpha segments' do
    expect(rv('1.a') <=> rv('1.1')).to eq(-1)
    expect(rv('1.a') <=> rv('1.b')).to eq(-1)
  end

  it 'handles tilde and caret' do
    expect(rv('1.0~rc1') <=> rv('1.0')).to eq(-1)
    expect(rv('1.0~rc1') <=> rv('1.0~rc2')).to eq(-1)
    expect(rv('1.0^git1') <=> rv('1.0')).to eq(1)
    expect(rv('1.0^git1') <=> rv('1.0.1')).to eq(-1)
  end

  it 'compares against nil, strings and FB::Version' do
    expect(rv('1.0') <=> nil).to eq(1)
    expect(rv(nil) <=> rv(nil)).to eq(0)
    expect(rv('0.7-2') <=> '0.7.1-1').to eq(-1)
    expect(rv('0.7-2') <=> FB::Version.new('0.7.1-1')).to eq(-1)
  end

  it 'keeps loose matching from FB::Version' do
    expect(rv('1.2.36') === rv('1.2')).to eq(true)
    expect(rv('1.2.36') === rv('1.1')).to eq(false)
  end

  it 'differs from FB::Version when the version gains a component' do
    expect(FB::Version.new('0.7-2') <=> FB::Version.new('0.7.1-1')).to eq(1)
  end
  # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands,Style/CaseEquality
end
