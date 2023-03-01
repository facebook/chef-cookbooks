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

require 'chef'
require_relative '../libraries/fb_helpers'

describe FB::Helpers do
  context 'evaluate_lazy_enumerable' do
    before do
      stub_const('Chef::VERSION', '17.0.42')
    end

    it 'makes no change to simple hash' do
      test_var = { 'test' => 'var' }

      expect(FB::Helpers.evaluate_lazy_enumerable(test_var)).to eq(test_var)
    end

    it 'evaluates a simple hash' do
      target = { 'test' => 'test' }
      test_var = { 'test' => FB::Helpers.attempt_lazy { 'test' } }

      expect(FB::Helpers.evaluate_lazy_enumerable(test_var)).to eq(target)
    end

    it 'evaluates a multi-level hash' do
      target = { 'level1' => {
        'level2' => 'test',
      } }
      test_var = { 'level1' => {
        'level2' => FB::Helpers.attempt_lazy { 'test' },
      } }

      expect(FB::Helpers.evaluate_lazy_enumerable(test_var)).to eq(target)
    end

    it 'evaluates a an array of hashes' do
      target = { 'level1' => [
        { 'array_1' => 'test' },
        { 'array_2' => 'test' },
      ] }
      test_var = { 'level1' => [
        { 'array_1' => FB::Helpers.attempt_lazy { 'test' } },
        { 'array_2' => FB::Helpers.attempt_lazy { 'test' } },
      ] }

      expect(FB::Helpers.evaluate_lazy_enumerable(test_var)).to eq(target)
    end

    it 'evaluates a an array of DelayedEvaluators' do
      target = ['test', 'test1']

      test_var = [
        FB::Helpers.attempt_lazy { 'test' },
        FB::Helpers.attempt_lazy { 'test1' },
      ]

      expect(FB::Helpers.evaluate_lazy_enumerable(test_var)).to eq(target)
    end
  end

  context 'attempt_lazy' do
    it 'returns a DelayedEvaluator for chef 17.0.42' do
      stub_const('Chef::VERSION', '17.0.42')
      test_var = 'start'

      res = FB::Helpers.attempt_lazy { test_var }
      test_var = 'updated'

      expect(res).to be_instance_of(Chef::DelayedEvaluator)
      expect(res.call).to eq('updated')
    end

    it 'returns a DelayedEvaluator for chef 18.0.92' do
      stub_const('Chef::VERSION', '18.0.92')
      test_var = 'start'

      res = FB::Helpers.attempt_lazy { test_var }
      test_var = 'updated'

      expect(res).to be_instance_of(Chef::DelayedEvaluator)
      expect(res.call).to eq('updated')
    end

    it 'returns a value for chef 16.5.77' do
      stub_const('Chef::VERSION', '16.5.77')
      test_var = 'start'

      res = FB::Helpers.attempt_lazy { test_var }
      test_var = 'updated'

      expect(res).to be_instance_of(String)
      expect(res).to eq('start')
    end
  end

  context 'parse_json' do
    it 'parses basic JSON' do
      expect(FB::Helpers.parse_json('{}')).to eq({})
    end

    it 'parses complex JSON' do
      json_str = '{"fb_sysctl": {"kernel.core_uses_pid": 0}}'
      json_hash = {
        'fb_sysctl' => {
          'kernel.core_uses_pid' => 0,
        },
      }
      expect(FB::Helpers.parse_json(json_str)).to eq(json_hash)
    end

    it 'ignores empty JSON' do
      expect(FB::Helpers.parse_json('', Hash, true)).to eq({})
    end

    it 'ignores invalid JSON' do
      expect(FB::Helpers.parse_json('"foo"', Hash, true)).to eq({})
    end

    it 'ignores broken JSON' do
      expect(FB::Helpers.parse_json('{bar}', Hash, true)).to eq({})
    end
  end

  context 'parse_json_file' do
    PATH = 'json_file.json'.freeze

    it 'ignores a file that cannot be read' do
      allow(File).to receive(:read).with(PATH).and_raise(IOError)
      expect(FB::Helpers.parse_json_file(PATH, Hash, true)).to eq({})
    end

    it 'parses a basic JSON file' do
      allow(File).to receive(:read).with(PATH).and_return('{}')
      expect(FB::Helpers.parse_json_file(PATH)).to eq({})
    end

    it 'parses a basic JSON file, and ignores empty JSON' do
      allow(File).to receive(:read).with(PATH).and_return('')
      expect(FB::Helpers.parse_json_file(PATH, Hash, true)).to eq({})
    end

    it 'parses a basic JSON file, and ignores invalid JSON' do
      allow(File).to receive(:read).with(PATH).and_return('"foo"')
      expect(FB::Helpers.parse_json_file(PATH, Hash, true)).to eq({})
    end

    it 'parses a basic JSON file, and ignores broken JSON' do
      allow(File).to receive(:read).with(PATH).and_return('{bar}')
      expect(FB::Helpers.parse_json_file(PATH, Hash, true)).to eq({})
    end
  end

  context 'parse_simple_keyvalue_file' do
    path = 'keyvalue_file.txt'.freeze

    it 'throws an error when told to read a file that cannot be read' do
      allow(IO).to receive(:readlines).with(path).and_raise(IOError)
      expect do
        FB::Helpers.parse_simple_keyvalue_file(path)
      end.to raise_error(RuntimeError)
    end

    it 'ignores a file that cannot be read when told to do so' do
      allow(IO).to receive(:readlines).with(path).and_raise(IOError)
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :fallback => true)).to eq({})
    end

    it 'parses an empty Key/Value file' do
      allow(IO).to receive(:readlines).with(path).and_return([])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({})
    end

    it 'parses a basic Key/Value file' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY=value'])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({ 'KEY' => 'value' })
    end

    it 'parses a basic Key/Value file with an empty value' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY='])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({ 'KEY' => '' })
    end

    it 'parses a basic Key/Value file with an empty value, coercing it to nil where required' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY='])
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :empty_value_is_nil => true)).to eq({ 'KEY' => nil })
    end

    it 'parses a basic Key/Value file, downcasing keys when told to' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY=value'])
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :force_downcase => true)).to eq({ 'key' => 'value' })
    end

    it 'parses a multiline Key/Value file' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY=value', 'KEY2=val'])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({ 'KEY' => 'value', 'KEY2' => 'val' })
    end

    it 'parses a basic Key/Value file with leading and trailing spaces' do
      allow(IO).to receive(:readlines).with(path).and_return([' KEY=value '])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({ 'KEY' => 'value' })
    end

    it 'parses a basic Key/Value file with spaces' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY = value'])
      expect(FB::Helpers.parse_simple_keyvalue_file(path)).to eq({ 'KEY' => 'value' })
    end

    it 'treats whitespace as semantic when required' do
      allow(IO).to receive(:readlines).with(path).and_return([' KEY = value '])
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :include_whitespace =>true)).to eq({ ' KEY ' => ' value ' })
    end

    it 'treats quotes as semantic when required - single quotes' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY = \'value\''])
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :exclude_quotes =>false)).to eq({ 'KEY' => '\'value\'' })
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :exclude_quotes =>true)).to eq({ 'KEY' => 'value' })
    end

    it 'treats quotes as semantic when required - double quotes' do
      allow(IO).to receive(:readlines).with(path).and_return(['KEY = "value"'])
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :exclude_quotes =>false)).to eq({ 'KEY' => '"value"' })
      expect(FB::Helpers.parse_simple_keyvalue_file(path, :exclude_quotes =>true)).to eq({ 'KEY' => 'value' })
    end
  end

  context 'parse a time for timeshard computation' do
    it 'should succeed with a valid timestamp - 2020-1-1 9:00:00' do
      expect(FB::Helpers.parse_timeshard_start(
               '2020-1-1 9:00:00 PST',
             )).to eq(1577898000)
    end

    it 'should fail if start_time is an invalid date - 2018-14-1 9:00:00' do
      expect do
        FB::Helpers.parse_timeshard_start('2018-14-1 9:00:00')
      end.to raise_error(RuntimeError)
    end
  end

  context 'parse a time for timeshard computation' do
    {
      '24h' => (24 * 60 * 60),
      '1h' => (60 * 60),
      '7d' => (7 * 24 * 60 * 60),
    }.each do |duration, seconds|
      it "should successfully parse #{duration}" do
        expect(FB::Helpers.parse_timeshard_duration(
                 duration,
               )).to eq(seconds)
      end
    end

    it 'should fail if duration is invalid - 43min' do
      expect do
        FB::Helpers.parse_timeshard_duration('43min')
      end.to raise_error(RuntimeError)
    end
  end

  context 'filter_hash' do
    it 'returns a passing hash unchanged' do
      hash = {
        'fb_sysctl' => {
          'kernel.core_uses_pid' => 0,
        },
      }
      filter = ['fb_sysctl']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq(hash)
    end

    it 'filters a failing hash' do
      hash = {
        'fb_sysctl' => {
          'kernel.core_uses_pid' => 0,
        },
      }
      expect(FB::Helpers.filter_hash(hash, [])).to eq({})
    end

    it 'returns a passing deep hash unchanged' do
      hash = {
        'fb_network_scripts' => {
          'ifup' => {
            'ethtool' => 'cookie',
          },
        },
      }
      filter = ['fb_network_scripts/ifup/ethtool']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq(hash)
    end

    it 'filters a failing deep hash' do
      hash = {
        'fb_network_scripts' => {
          'ifup' => {
            'extra_commands' => 'cookie',
          },
        },
      }
      filter = ['fb_network_scripts/ifup/ethtool']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq({})
    end

    it 'handles compound hashes and filters' do
      hash = {
        'fb_sysctl' => {
          'kernel.core_uses_pid' => 0,
        },
        'fb_network_scripts' => {
          'ifup' => {
            'ethtool' => 'cookie',
            'boo' => 123,
          },
        },
        'fb_foo' => {
          'bar' => 4,
        },
      }
      filtered_hash = {
        'fb_sysctl' => {
          'kernel.core_uses_pid' => 0,
        },
        'fb_network_scripts' => {
          'ifup' => {
            'ethtool' => 'cookie',
          },
        },
      }
      filter = ['fb_sysctl', 'fb_network_scripts/ifup/ethtool']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq(filtered_hash)
    end

    it 'handles hashes with empty values' do
      hash = {
        'fb_network_scripts' => {
          'ifup' => {
            'extra_commands' => {},
          },
        },
      }

      filter = ['fb_network_scripts/ifup/extra_commands']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq(hash)
    end

    it 'handles multiple filters on the same hash' do
      hash = {
        'foo' => {
          'bar' => 1,
          'baz' => 2,
        },
      }
      hash2 = {
        'foo' => {
          'bar' => 1,
          'baz' => 2,
          'boo' => 3,
        },
      }
      filter = ['foo/bar', 'foo/baz']
      expect(FB::Helpers.filter_hash(hash, filter)).to eq(hash)
      expect(FB::Helpers.filter_hash(hash2, filter)).to eq(hash)
    end
  end

  # These tests are based on spec/unit/mixin/deep_merge_spec.rb from
  # https://github.com/chef/chef at revision
  # 5c8383fedd13b07f13d64a58f7cc78664a235ced
  context 'merge_hash' do
    it 'merges Hashes like normal deep merge' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => '1-a-merge-ee',
          '1_deep_b' => '1-deep-b-merge-ee',
        },
        'top_level_b' => 'top-level-b-merge-ee',
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_b' => '1-deep-b-merged-onto',
          '1_deep_c' => '1-deep-c-merged-onto',
        },
        'top_level_b' => 'top-level-b-merged-onto',
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)

      expect(merged_result['top_level_b']).to eq('top-level-b-merged-onto')
      expect(merged_result['top_level_a']['1_deep_a']).to eq('1-a-merge-ee')
      expect(merged_result['top_level_a']['1_deep_b']).
        to eq('1-deep-b-merged-onto')
      expect(merged_result['top_level_a']['1_deep_c']).
        to eq('1-deep-c-merged-onto')
    end

    it 'replaces arrays rather than merging them' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => '1-a-merge-ee',
          '1_deep_b' => %w{A A A},
        },
        'top_level_b' => 'top-level-b-merge-ee',
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_b' => %w{B B B},
          '1_deep_c' => '1-deep-c-merged-onto',
        },
        'top_level_b' => 'top-level-b-merged-onto',
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)

      expect(merged_result['top_level_b']).to eq('top-level-b-merged-onto')
      expect(merged_result['top_level_a']['1_deep_a']).to eq('1-a-merge-ee')
      expect(merged_result['top_level_a']['1_deep_b']).to eq(%w{B B B})
    end

    it 'replaces non-hash items with hashes when there is a conflict' do
      merge_ee_hash = {
        'top_level_a' => 'top-level-a-mergee',
        'top_level_b' => 'top-level-b-merge-ee',
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_b' => %w{B B B},
          '1_deep_c' => '1-deep-c-merged-onto',
        },
        'top_level_b' => 'top-level-b-merged-onto',
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)

      expect(merged_result['top_level_a']).to be_a(Hash)
      expect(merged_result['top_level_a']['1_deep_a']).to be_nil
      expect(merged_result['top_level_a']['1_deep_b']).to eq(%w{B B B})
    end

    it 'does not mutate deeply-nested original hashes by default' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_a' => 'foo',
            },
          },
        },
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_b' => 'bar',
            },
          },
        },
      }

      FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)

      expect(merge_ee_hash).to eq({
                                    'top_level_a' => {
                                      '1_deep_a' => {
                                        '2_deep_a' => {
                                          '3_deep_a' => 'foo',
                                        },
                                      },
                                    },
                                  })
      expect(merge_with_hash).to eq({
                                      'top_level_a' => {
                                        '1_deep_a' => {
                                          '2_deep_a' => {
                                            '3_deep_b' => 'bar',
                                          },
                                        },
                                      },
                                    })
    end

    it 'does not error merging un-dupable items' do
      merge_ee_hash = {
        'top_level_a' => 1,
        'top_level_b' => false,
      }
      merge_with_hash = {
        'top_level_a' => 2,
        'top_level_b' => true,
      }

      FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)
    end

    it 'merges leaf Hashes by default' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_a' => 'foo',
            },
          },
        },
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_b' => 'bar',
            },
          },
        },
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash)

      expect(merged_result).to eq({
                                    'top_level_a' => {
                                      '1_deep_a' => {
                                        '2_deep_a' => {
                                          '3_deep_a' => 'foo',
                                          '3_deep_b' => 'bar',
                                        },
                                      },
                                    },
                                  })
    end

    it 'overwrites leaf Hashes if requested' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_a' => 'foo',
            },
          },
        },
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_b' => 'bar',
            },
          },
        },
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash,
                                             true)

      expect(merged_result).to eq({
                                    'top_level_a' => {
                                      '1_deep_a' => {
                                        '2_deep_a' => {
                                          '3_deep_b' => 'bar',
                                        },
                                      },
                                    },
                                  })
    end

    it 'does not clobber top-level Hashes when overwriting leaves' do
      merge_ee_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_a' => 'foo',
            },
          },
          '1_deep_b' => 1,
        },
      }
      merge_with_hash = {
        'top_level_a' => {
          '1_deep_a' => {
            '2_deep_a' => {
              '3_deep_b' => 'bar',
            },
          },
        },
      }

      merged_result = FB::Helpers.merge_hash(merge_ee_hash, merge_with_hash,
                                             true)

      expect(merged_result).to eq({
                                    'top_level_a' => {
                                      '1_deep_a' => {
                                        '2_deep_a' => {
                                          '3_deep_b' => 'bar',
                                        },
                                      },
                                      '1_deep_b' => 1,
                                    },
                                  })
    end
  end
end
