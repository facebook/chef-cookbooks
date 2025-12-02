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
#

module FB
  class Grafana
    module Provider
      def load_current_plugins
        s = Mixlib::ShellOut.new('grafana-cli plugins ls').run_command
        s.error!
        plugins = {}
        s.stdout.each_line do |line|
          next unless line =~ / @ /

          name, version = line.chomp.strip.split(' @ ')
          plugins[name] = version
        end
        plugins
      end

      def load_available_plugins
        s = Mixlib::ShellOut.new('grafana-cli plugins list-remote').run_command
        s.error!
        plugins = {}
        s.stdout.each_line do |line|
          next unless line.start_with?('id:')

          m = line.chomp.match(/^id: (.*) version: (.*)$/)
          plugins[m[1]] = m[2]
        end
        plugins
      end
    end
  end
end
