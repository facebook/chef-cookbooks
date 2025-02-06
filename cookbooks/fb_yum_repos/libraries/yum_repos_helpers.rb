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
  class YumRepos
    # By convention, some keys in the config use numbers instead of strings to
    # represent booleans; track these accordingly to minimize confusion.
    NUMBER_BOOLEAN_KEYS = [
      'gpgcheck',
      'enabled',
      'countme',
      'repo_gpgcheck',
      'module_hotfixes',
      'antlir_extra_repo',
    ].freeze

    def self.get_default_gpg_key(_node)
      value_for_platform(
        :centos => {
          :default => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial',
        },
        :fedora => {
          :default =>
            'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch',
        },
        :rocky=> {
          :default =>
            'https://dl.rockylinux.org/pub/rocky/9/metadata/RPM-GPG-KEY-Rocky-9',
        },
      )
    end

    def self.gen_repo_config(node, name, config = {})
      unless node.centos? || node.fedora? || node.rocky?
        fail "fb_yum_repos[gen_repo_config]: unsupported platform #{platform}"
      end

      unless config['name']
        config['name'] = name
      end

      if !config['mirrorlist'] && !config['metalink'] && !config['baseurl']
        fail 'fb_yum_repos[gen_repo_config]: one of mirrorlist, metalink or ' +
             'baseurl must be specified!'
      end

      if config['gpgcheck'].nil?
        config['gpgcheck'] = true
      end

      if config['enabled'].nil?
        config['enabled'] = true
      end

      if (
          config['gpgcheck'] == true ||
          config['gpgcheck'] == '1'
      ) && !config['gpgkey']
        config['gpgkey'] = self.get_default_gpg_key(node)
      end

      config
    end

    def self.gen_repo_entry(node, name, config = {})
      out = "\n[#{name}]\n"
      self.gen_repo_config(node, name, config).each do |key, val|
        v = self.gen_config_value(key, val)
        out += "#{key}=#{v}\n"
      end

      out
    end

    def self.gen_group_config(_node, name, config = {})
      unless config['repos']
        fail 'fb_yum_repos[self.gen_group_config]: no repos defined for ' +
             "group #{name}"
      end

      unless config['description']
        config['description'] = name
      end

      config
    end

    def self.gen_group_entry(node, name, config = {})
      config = self.gen_group_config(node, name, config)

      out = "\n# #{config['description']}\n"
      config['repos'].each do |repo, repo_config|
        out += self.gen_repo_entry(node, repo, repo_config)
      end

      out
    end

    def self.gen_config_value(key, value)
      if value.is_a?(TrueClass) || value.to_s.strip == '1'
        if NUMBER_BOOLEAN_KEYS.include?(key)
          '1'
        else
          'True'
        end
      elsif value.is_a?(FalseClass) || value.to_s.strip == '0'
        if NUMBER_BOOLEAN_KEYS.include?(key)
          '0'
        else
          'False'
        end
      elsif value.is_a?(Array)
        value.join(' ')
      else
        value.to_s.strip
      end
    end
  end
end
