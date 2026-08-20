#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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
  class SSH
    def self.confdir(node)
      node.windows? ? 'C:/ProgramData/ssh' : '/etc/ssh'
    end

    # some configuration keys do not accept space-separated values. Most
    # do, but a few require you to define the key several times.
    #
    # unfortuately, most can't be defined multiple times, so there's no
    # one option that works for both.
    #
    # since nearly everything allows space-separated values, we hard-code
    # the special-case ones that require multi-defining
    MULTI_DEFINE_CONFIG_KEYS = [
      'HostKey',
      'ListenAddress',
      'IdentityFile',
    ].freeze

    DESTDIR = {
      'keys' => 'authorized_keys',
      'principals' => 'authorized_princs',
    }.freeze
  end
end
