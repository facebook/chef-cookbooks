#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc.
# Copyright (c) 2025-present, Phil Dibowitz
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
  class Bind
    CONFIG_DIR = '/etc/bind'.freeze

    V6_LOOPBACK_ZONENAME = (
      '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0' +
      '.ip6.arpa'
    ).freeze

    INTERNAL_SOA = {
      'type' => 'SOA',
      'mname' => 'localhost.',
      'rname' => 'root.localhost.',
      # RH defaults to 0, Debian to 2, so just don't go backwards
      'serial' => 2,
      'refresh' => '1d',
      'retry' => '1h',
      'expire' => '4w',
      'negative-cache-ttl' => '7d',
    }.freeze

    LOCALHOST_ZONEDATA = {
      'ttl' => '1d',
      'soa' => INTERNAL_SOA,
      'root ns' => {
        'type' => 'NS',
        'value' => 'localhost.',
      },
      'root v4' => {
        'type' => 'A',
        'value' => '127.0.0.1',
      },
      'root v6' => {
        'type' => 'AAAA',
        'value' => '::1',
      },
    }.freeze

    LOOPBACK_ZONEDATA = {
      'ttl' => '1d',
      'soa' => INTERNAL_SOA,
      'root ns' => {
        'type' => 'NS',
        'value' => 'localhost.',
      },
      'root ptr' => {
        'name' => '1.0.0',
        'type' => 'PTR',
        'value' => 'localhost.',
      },
    }.freeze

    LOOPBACK6_ZONEDATA = {
      'ttl' => '1d',
      'soa' => INTERNAL_SOA,
      'root ns' => {
        'type' => 'NS',
        'value' => 'localhost.',
      },
      # since the zone is just ::1, no name, it's doman PTR
      'root ptr' => {
        'type' => 'PTR',
        'value' => 'localhost.',
      },
    }.freeze

    STUB_ZONEDATA = {
      'ttl' => '1d',
      'soa' => INTERNAL_SOA,
      'root ns' => {
        'type' => 'NS',
        'value' => 'localhost.',
      },
    }.freeze

    CACHE_FILE = File.join(
      Chef::Config['file_cache_path'],
      'fb_bind_resolve_cache.json',
    )

    def self._read_cachefile
      data = {}
      if File.exist?(CACHE_FILE)
        data = begin
          JSON.parse(File.read(CACHE_FILE))
        rescue StandardError => e
          Chef::Log.warn(
            "fb_bind: Failed to parse stable-dns-cache: #{e.message}",
          )
          {}
        end
      end
      data
    end

    def self.dns_cachedata(node)
      unless node.run_state['fb_bind_dns_cachedata']
        node.run_state['fb_bind_dns_cachedata'] = {
          'prev' => _read_cachefile,
          'new' => {},
        }
      end
      return node.run_state['fb_bind_dns_cachedata']
    end

    def self.stable_resolve(name, node, allow_failure = false)
      cache = dns_cachedata(node)
      if cache['new'][name]
        Chef::Log.debug(
          'fb_bind[stable_resolve]: Returning already-resolved answer for' +
          " #{name}.",
        )
        return cache['new'][name]
      end
      begin
        res = Addrinfo.getaddrinfo(name, nil)
        addrs = res.map(&:ip_address).sort.uniq
        cache['new'][name] = addrs
      rescue StandardError => e
        Chef::Log.debug("Got error #{e} resolving #{name}")
        if cache['prev'][name]
          Chef::Log.warn(
            "fb_bind[stable_resolve]: Failed to resolve #{name}, falling back" +
            " to cached value: #{cache['prev'][name]}",
          )
          # populate this name in the 'new' cache, so we don't try to look
          # it up a second time in the same run
          cache['new'][name] = cache['prev'][name].dup
          return cache['prev'][name]
        end
        if allow_failure
          Chef::Log.error(
            "fb_bind[stable_resolve]: Failed to resolve #{name}, no values in" +
            ' cache, *and* `allow_failure` set, returning no addresses!',
          )
          # do *not* populate new cache in this instance, as it's not valid
          # data and we don't want to persist it
          return []
        end
        raise "fb_bind[stable_resolve]: Failed to resolve #{name}, no values" +
          ' cache, so failing run.'
      end
      addrs
    end

    def self.populate_empty_rfc1918_zones(node)
      zones = %w{10 168.192} + (16..31).map { |x| "#{x}.172" }
      zones.each do |zone|
        node.default['fb_bind']['zones']["#{zone}.in-addr.arpa"] = {
          'type' => 'primary',
          '_records' => STUB_ZONEDATA,
        }
      end
    end
  end
end
