# Copyright (c) 2022-present, Meta Platforms, Inc. and affiliates
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
  class AvoidUnicode < Base
    MSG = fb_msg('Unicode within ruby files will cause weird errors - this will most likely fail during the chef run')

    # if a user sends to a unicode, this is almost always a paste error.  If only we
    # could restrict_on_send to a regex, we could limit this there - but this seems fast
    # enough...
    def on_send(node)
      unless node.method_name.to_s.ascii_only?
        add_offense(node, :severity => :error)
      end
    end

    # if the user hit something ruby considers a capital letter with their unicode, catch that too...
    def on_const(node)
      unless node.to_s.ascii_only?
        add_offense(node, :severity => :error)
      end
    end
  end
end
