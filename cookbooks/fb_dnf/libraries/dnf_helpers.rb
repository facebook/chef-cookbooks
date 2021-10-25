# Copyright (c) 2021-present, Facebook, Inc.
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

module FB
  class Dnf
    def self.gen_module_yaml(module_name, module_data)
      data = {
        'document' => 'modulemd-defaults',
        'version' => 1,
        'data' => {
          'module' => module_name,
          # currently local files do not win,
          # so we set modified to a date far in the future
          'modified' => 901812071200,
        },
      }
      ['stream', 'profiles'].each do |key|
        if module_data[key]
          data['data'][key] = module_data[key]
        end
      end
      data.to_yaml
    end
  end
end
