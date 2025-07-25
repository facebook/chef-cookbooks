require './spec/spec_helper'
require_relative '../libraries/redacted_string'

describe 'Chef::FB::Helpers' do
  context 'Chef::FB::Helpers::RedactedString' do
    it 'should not return the secret on to_s' do
      expect(FB::Helpers::RedactedString.new('test secret').to_s).to eq('**REDACTED**')
    end
    it 'should not return the secret on to_str' do
      expect(FB::Helpers::RedactedString.new('test secret').to_str).to eq('**REDACTED**')
    end
    it 'should not return the secret on inspect' do
      expect(FB::Helpers::RedactedString.new('test secret').inspect).to eq('"***REDACTED***"')
    end
    it 'should return the secret on value' do
      expect(FB::Helpers::RedactedString.new('test secret').value).to eq('test secret')
    end
    it 'should be frozen' do
      expect(FB::Helpers::RedactedString.new('test secret').frozen?).to eq(true)
    end
  end
end
