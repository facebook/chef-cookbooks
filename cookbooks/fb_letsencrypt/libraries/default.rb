#
# Copyright:: 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright:: 2025-present, Phil Dibowitz
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

# rubocop:disable Style/ClassVars
module FB
  class LetsEncrypt
    # Makes all these class methods without the `self.` and allows
    # `alias` to work.
    class << self
      @@base_dir = nil

      def _base_dir(node)
        @@base_dir ||= node.value_for_platform(
          :windows => {
            :default => ::File.join('C:\certbot', 'live'),
          },
          :default => ::File.join('/etc', 'letsencrypt', 'live'),
        )
      end

      def _pki_path(node, name, filetype)
        ::File.join(_base_dir(node), name, "#{filetype}.pem")
      end

      def cert(node, name)
        _pki_path(node, name, 'fullchain')
      end
      alias certificate cert
      alias fullchain cert
      alias crt cert

      def privkey(node, name)
        _pki_path(node, name, 'privkey')
      end
      alias privatekey privkey
      alias key privkey

      def minimal_cert(node, name)
        _pki_path(node, name, 'cert')
      end

      def onlychain(node, name)
        _pki_path(node, name, 'chain')
      end
    end
  end
end
# rubocop:enable Style/ClassVars
