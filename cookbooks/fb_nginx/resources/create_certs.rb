#
# Cookbook:: fb_nginx
# Recipe:: default
#
# Copyright (c) 2019-present, Vicarious, Inc.
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

action :enable do
  node['fb_nginx']['sites'].each do |site, config|
    if !config['_create_self_signed_cert'] || !config['ssl_certificate'] ||
       !config['ssl_certificate_key']
      Chef::Log.debug(
        "fb_nginx[#{site}]: Not creating cert: missing " +
        '"ssl_certificate", "ssl_certificate_key", or ' +
        '"_create_self_signed_cert"',
      )
      next
    end
    if ::File.exist?(config['ssl_certificate'])
      Chef::Log.debug(
        "fb_nginx[#{site}]: Not creating cert: it already exists.",
      )
      next
    end

    unless ::File.exist?('/usr/bin/openssl')
      Chef::Log.error(
        "fb_nginx[#{site}]: Cannot create certificates because no " +
        'openssl is available',
      )
      next
    end

    execute "create key/cert for #{site}" do
      command 'openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 ' +
        "-nodes -out #{config['ssl_certificate']} " +
        "-keyout #{config['ssl_certificate_key']} " +
        "-subj '/C=US/ST=California/L=Some City/O=Some Org/CN=#{site}'"
    end
  end
end
