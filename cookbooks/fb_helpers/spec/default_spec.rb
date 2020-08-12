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

require_relative '../libraries/fb_helpers.rb'

describe FB::Helpers do
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
  end
end
