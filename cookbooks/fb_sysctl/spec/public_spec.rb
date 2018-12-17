# Copyright (c) 2018-present, Facebook, Inc.

require 'chef/node'
require_relative '../libraries/sync.rb'

describe FB::Sysctl do
  context '#incorrect_settings' do
    it 'treats identical settings as the same' do
      FB::Sysctl.incorrect_settings(
        { 'somekey' => '1 2 val thing' },
        { 'somekey' => '1 2 val thing' },
      ).should eq({})
    end

    it 'treats settings with whitespace differences the same' do
      FB::Sysctl.incorrect_settings(
        { 'somekey' => '1  2    val thing' },
        { 'somekey' => '1 2 val thing' },
      ).should eq({})
    end

    it 'treats different settings as different' do
      FB::Sysctl.incorrect_settings(
        { 'somekey' => '1 3 val thing' },
        { 'somekey' => '1 2 val thing' },
      ).should eq({ 'somekey' => '1 3 val thing' })
    end

    it 'handles integers and strings correctly' do
      FB::Sysctl.incorrect_settings(
        { 'somekey' => 12 },
        { 'somekey' => '12' },
      ).should eq({})
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
      FB::Sysctl.incorrect_settings(
        current,
        desired,
      ).should eq(
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
      FB::Sysctl.incorrect_settings(
        { 'real_key' => 'val', 'extra_key' => 'val2' },
        { 'real_key' => 'val' },
      ).should eq({})
    end
  end
end
