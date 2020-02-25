# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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
  # e2fsprogs utility functions
  class E2fsprogs
    # Internal helper function to generate e2fsprogs config entries
    def self._gen_e2fsprogs_config(k, v, i = 0)
      indent = ' ' * i
      if v.is_a?(Hash)
        s = "#{indent}#{k} = {\n"
        v.each do |kk, vv|
          s += self._gen_e2fsprogs_config(kk, vv, i + 2)
        end
        s += "}\n"
        return s
      elsif v.is_a?(Array)
        return "#{indent}#{k} = #{v.join(',')}\n"
      elsif v.is_a?(TrueClass)
        return "#{indent}#{k} = 1\n"
      elsif v.is_a?(FalseClass)
        return "#{indent}#{k} = 0\n"
      else
        return "#{indent}#{k} = #{v}\n"
      end
    end
  end
end
