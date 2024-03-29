#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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
  class Sysfs
    module Provider
      def check(current, new, type)
        case type
        when :list
          current.include?("[#{new.chomp}]")
        when :int
          current.to_i == new.to_i
        else
          current.chomp == new.chomp
        end
      end

      def create_set_on_boot_hash(node, type, path, content)
        if type==:list
          node.default['fb_sysfs']['_set_on_boot'][path]= "#{content.to_s.chomp}\n"

        else
          node.default['fb_sysfs']['_set_on_boot'][path]= content.to_s
        end
      end
    end
  end
end
