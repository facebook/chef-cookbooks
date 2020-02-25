# Copyright (c) 2018-present, Facebook, Inc.
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
  class Screen
    def self.screen_session_active?
      session_active = false
      Dir.glob('/var/run/screen/**/*') do |path|
        st = File.lstat(path)
        # GNU screen might use a pipe or a socket, depending on how
        # it was compiled
        if st.pipe? || st.socket?
          session_active = true
        end
      end
      return session_active
    end
  end
end
