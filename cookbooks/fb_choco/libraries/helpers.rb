# Copyright (c) 2020-present, Facebook, Inc.
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
# Cookbook Name:: fb_choco
# Libraries:: helpers

module FB
  class Choco
    module Helpers
      def get_choco_bin
        extend Chef::Mixin::Which
        file_name = 'choco.exe'

        # "which" uses $env:PATH to find the chocolatey binary.  When
        # chocolatey is installed it will update $env:PATH, however
        # this requires the shell to be restarted.  If which does not find
        # choco.exe in $env:PATH it returns 'nil'
        # In this situtation lets also check the most likely location.
        which_path = which(file_name)
        return which_path unless which_path.nil? || (which_path == false)

        expected_paths = [
          "C:\\ProgramData\\Chocolatey\\bin\\#{file_name}",
        ]
        expected_paths.each do |expected_path|
          return expected_path if ::File.exist?(expected_path)
        end
        return nil
      end
    end
  end
end
