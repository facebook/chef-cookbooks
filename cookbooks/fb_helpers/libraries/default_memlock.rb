# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module FB
  class Helpers
    def self.default_memlock_kbytes(node, use_scaled_limit:)
      total_system_memory_kbytes = node['memory']['total'].to_i
      return total_system_memory_kbytes / 1024 unless use_scaled_limit

      # Use min(max(total / 128, min(1 GiB, total / 8)), 4 GiB).
      # The total / 8 bound keeps seven eighths of memory available on hosts
      # that have less than 8 GiB of memory.
      minimum_memlock_limit_kbytes = [
        1024 * 1024,
        total_system_memory_kbytes / 8,
      ].min
      [
        [total_system_memory_kbytes / 128, minimum_memlock_limit_kbytes].max,
        4 * 1024 * 1024,
      ].min
    end
  end
end
