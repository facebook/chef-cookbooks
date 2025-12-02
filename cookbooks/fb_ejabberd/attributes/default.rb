#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
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

default['fb_ejabberd'] = {
  'manage_packages' => true,
  'extra_packages' => [],
  'sysconfig' => {
    'erl_options' => '-env ERL_CRASH_DUMP_BYTES 0',
    'erlang_node' => "ejabberd@#{node['hostname']}",
    'ejabberd_pid_path' => '/run/ejabberd/ejabberd.pid',
  },
  'config' => {
    'loglevel' => 5,
    'log_rotate_size' => 'infinity',
    'hosts' => [],
    'certfiles' => [],
    'acme' => {
      'auto' => false,
    },
    'define_macro' => {
      'TLS_CIPHERS' => 'HIGH:!aNULL:!eNULL:!3DES:@STRENGTH',
      'TLS_OPTIONS' => [
        'no_sslv3',
        'no_tlsv1',
        'no_tlsv1_1',
        'cipher_server_preference',
        'no_compression',
      ],
    },
    'c2s_ciphers' => 'TLS_CIPHERS',
    's2s_ciphers' => 'TLS_CIPHERS',
    'c2s_protocol_options' => 'TLS_OPTIONS',
    's2s_protocol_options' => 'TLS_OPTIONS',
    'listen' => [
      {
        'port' => 5222,
        'ip' => '::',
        'module' => 'ejabberd_c2s',
        'max_stanza_size' => 262144,
        'shaper' => 'c2s_shaper',
        'access' => 'c2s',
        'starttls' => true,
        'starttls_required' => true,
        'protocol_options' => 'TLS_OPTIONS',
      },
      {
        'port' => 5269,
        'ip' => '::',
        'module' => 'ejabberd_s2s_in',
      },
    ],
    'disable_sasl_mechanisms' => [
      'digest-md5',
      'X-OAUTH2',
    ],
    's2s_use_starttls' => 'required',
    'auth_method' => 'internal',
    'resource_conflict' => 'closeold',
    'auth_password_format' => 'scram',
    'shaper' => {
      'normal' => {
        'rate' => 3000,
        'burst_size' => 20000,
      },
      'fast' => 200000,
    },
    'shaper_rules' => {
      'max_user_sessions' => 10,
      'max_user_offline_messages' => {
        5000 => 'admin',
        100 => 'all',
      },
      'c2s_shaper' => {
        'none' => 'admin',
        'normal' => 'all',
      },
      's2s_shaper' => 'fast',
    },
    'max_fsm_queue' => 1000,
    'acl' => {
      'local' => {
        'user_regexp' => '',
      },
      'loopback' => {
        'ip' => [
          '127.0.0.0/8',
        ],
      },
    },
    'access_rules' => {
      'local' => {
        'allow' => 'local',
      },
      'c2s' => {
        'deny' => 'blocked',
        'allow' => 'all',
      },
      'announce' => {
        'allow' => 'admin',
      },
      'configure' => {
        'allow' => 'admin',
      },
      'muc_create' => {
        'allow' => 'local',
      },
      'pubsub_createnode' => {
        'allow' => 'local',
      },
      'trusted_network' => {
        'allow' => 'loopback',
      },
    },
    'api_permissions' => {
      'console commands' => {
        'from' => [
          'ejabberd_ctl',
        ],
        'who' => 'all',
        'what' => '*',
      },
      'admin access' => {
        'who' => {
          'access' => {
            'allow' => [
              { 'acl' => 'loopback' },
              { 'acl' => 'admin' },
            ],
          },
          'oauth' => {
            'scope' => 'ejabberd:admin',
            'access' => {
              'allow' => [
                { 'acl' => 'loopback' },
                { 'acl' => 'admin' },
              ],
            },
          },
        },
        'what' => [
          '*',
          '!stop',
          '!start',
        ],
      },
      'public commands' => {
        'who' => {
          'ip' => '127.0.0.1/8',
        },
        'what' => [
          'status',
          'connected_users_number',
        ],
      },
    },
    'language' => 'en',
    'modules' => {
      'mod_adhoc' => {},
      'mod_admin_extra' => {},
      'mod_announce' => {
        'access' => 'announce',
      },
      'mod_blocking' => {},
      'mod_bosh' => {},
      'mod_caps' => {},
      'mod_carboncopy' => {},
      'mod_configure' => {},
      'mod_disco' => {},
      'mod_fail2ban' => {},
      'mod_http_api' => {},
      'mod_last' => {},
      'mod_mqtt' => {},
      'mod_muc' => {
        'access' => [
          'allow',
        ],
        'access_admin' => [
          {
            'allow' => 'admin',
          },
        ],
        'access_create' => 'muc_create',
        'access_persistent' => 'muc_create',
        'access_mam' => [
          'allow',
        ],
        'default_room_options' => {
          'mam' => true,
        },
      },
      'mod_muc_admin' => {},
      'mod_offline' => {
        'access_max_user_messages' => 'max_user_offline_messages',
      },
      'mod_ping' => {},
      'mod_privacy' => {},
      'mod_private' => {},
      'mod_pubsub' => {
        'access_createnode' => 'pubsub_createnode',
        'ignore_pep_from_offline' => true,
        'last_item_cache' => false,
        'plugins' => [
          'flat',
          'pep',
        ],
        'force_node_config' => {
          'eu.siacs.conversations.axolotl.*' => {
            'access_model' => 'open',
          },
          'storage:bookmarks:' => {
            'access_model' => 'whitelist',
          },
        },
      },
      'mod_push' => {},
      'mod_push_keepalive' => {},
      'mod_register' => {
        'welcome_message' => {
          'subject' => 'Welcome!',
          'body' => "Hi.\nWelcome to this XMPP server.\n",
        },
        'ip_access' => 'trusted_network',
        'access' => 'register',
      },
      'mod_roster' => {
        'versioning' => true,
      },
      'mod_s2s_dialback' => {},
      'mod_shared_roster' => {},
      'mod_sic' => {},
      'mod_stream_mgmt' => {
        'resend_on_timeout' => 'if_offline',
      },
      'mod_stun_disco' => {},
      'mod_stats' => {},
      'mod_time' => {},
      'mod_vcard' => {
        'search' => false,
      },
      'mod_vcard_xupdate' => {},
      'mod_version' => {},
    },
  },
}
