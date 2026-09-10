require './spec/spec_helper'
require_relative '../libraries/default_memlock'

describe FB::Helpers do
  gibibyte_in_kibibytes = 1024 * 1024

  def node_with_memory(total_memory_kibibytes)
    {
      'memory' => {
        'total' => "#{total_memory_kibibytes}kB",
      },
    }
  end

  describe '.default_memlock_kbytes' do
    it 'returns a 1/1024 RAM limit for the explicit legacy path' do
      total_memory_kibibytes = 256 * gibibyte_in_kibibytes

      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(total_memory_kibibytes),
        :use_scaled_limit => false,
      )

      expect(limit).to eq(total_memory_kibibytes / 1024)
    end

    it 'uses one eighth of RAM below 8 GiB' do
      total_memory_kibibytes = 4 * gibibyte_in_kibibytes

      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(total_memory_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(total_memory_kibibytes / 8)
    end

    it 'uses 1 GiB at the 8 GiB boundary' do
      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(8 * gibibyte_in_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(gibibyte_in_kibibytes)
    end

    it 'uses the 1 GiB floor' do
      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(64 * gibibyte_in_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(gibibyte_in_kibibytes)
    end

    it 'uses 1 GiB at the 128 GiB boundary' do
      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(128 * gibibyte_in_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(gibibyte_in_kibibytes)
    end

    it 'uses proportional scaling between the floor and cap' do
      total_memory_kibibytes = 256 * gibibyte_in_kibibytes

      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(total_memory_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(total_memory_kibibytes / 128)
    end

    it 'uses 4 GiB at the 512 GiB boundary' do
      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(512 * gibibyte_in_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(4 * gibibyte_in_kibibytes)
    end

    it 'uses the 4 GiB cap' do
      limit = FB::Helpers.default_memlock_kbytes(
        node_with_memory(1024 * gibibyte_in_kibibytes),
        :use_scaled_limit => true,
      )

      expect(limit).to eq(4 * gibibyte_in_kibibytes)
    end
  end
end
