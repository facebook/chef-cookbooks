# Copyright (c) 2024-present, Meta Platforms, Inc. and affiliates
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

module RuboCop::Cop::Chef::Meta
  class PreferPowershellExec < Base
    MSG = fb_msg('powershell_out has a 7 second per call performance penalty.  ' +
                 'Unless you really need an interactive shell, try `powershell_exec` instead')

    RESTRICT_ON_SEND = [:powershell_out, :powershell_out!].freeze

    def on_send(node)
      add_offense(node, :severity => :info)
    end
  end
end
