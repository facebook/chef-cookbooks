# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2011-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

default['fb_postfix'] = {
  'enable' => true,
  'aliases' => {},
  'access' => {},
  'canonical' => {},
  'etrn_access' => {
    '127.0.0.1' => 'OK',
  },
  'local_access' => {},
  'localdomains' => [],
  'main.cf' => {
    'daemon_directory' => '/usr/libexec/postfix',
    'queue_directory' => '/var/spool/postfix',
    'mail_owner' => 'postfix',
    'mynetworks' => '/etc/postfix/mynetworks',
    'relay_domains' => '/etc/postfix/relaydomains',
    'alias_maps' => 'hash:/etc/postfix/aliases',
    'recipient_delimiter' => '+',
    'smtpd_banner' => '$myhostname ESMTP',
    'debug_peer_level' => 2,
    'debugger_command' =>
      'PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin ' +
      'ddd $daemon_directory/$process_name $process_id & sleep 5',
    'newaliases_path' => '/usr/bin/newaliases.postfix',
    'alias_database' => 'hash:/etc/postfix/aliases',
    'disable_vrfy_command' => 'yes',
    'smtpd_client_restrictions' =>
      'hash:/etc/postfix/access, permit_mynetworks',
    'smtpd_helo_required' => 'yes',
    'smtpd_recipient_restrictions' =>
      'check_recipient_access hash:/etc/postfix/local_access,' +
      'permit_mynetworks, reject_unauth_destination',
    'biff' => 'no',
    'require_home_directory' => 'no',
    'local_transport' => 'local',
    'forward_path' =>
      '$home/.forward$recipient_delimiter$extension,$home/.forward',
    'allow_mail_to_commands' => 'alias,forward',
    'allow_mail_to_files' => 'alias,forward',
    'readme_directory' => 'no',
    'sample_directory' => '/etc/postfix',
    'sendmail_path' => '/usr/sbin/sendmail.postfix',
    'setgid_group' => 'postdrop',
    'manpage_directory' => '/usr/share/man',
    'mailq_path' => '/usr/bin/mailq.postfix',
    'mydestination' =>
        '$myhostname, localhost.$mydomain /etc/postfix/localdomains',
    'myorigin' => '$myhostname',
    'inet_protocols' => 'all',
    'header_checks' => 'regexp:/etc/postfix/custom_headers.regexp',
    '2bounce_notice_recipient' => nil,
    'bounce_notice_recipient' => nil,
    'bounce_queue_lifetime' => nil,
    'command_expansion_filter' => nil,
    'command_time_limit' => nil,
    'default_destination_concurrency_limit' => '10',
    'default_privs' => 'nobody',
    'default_process_limit' => nil,
    'export_environment' => nil,
    'home_mailbox' => 'Mailbox',
    'inet_interfaces' => 'loopback-only',
    'initial_destination_concurrency' => nil,
    'local_destination_concurrency_limit' => '2',
    'local_recipient_maps' => '$alias_maps unix:passwd.byname',
    'luser_relay' => nil,
    'mailbox_command' => '/usr/bin/procmail',
    'mailbox_size_limit' => nil,
    'maximal_backoff_time' => '300',
    'maximal_queue_lifetime' => nil,
    'message_size_limit' => nil,
    'minimal_backoff_time' => '120',
    'mydomain' => 'fb.com',
    'queue_run_delay' => '60',
    'smtpd_client_connection_count_limit' => nil,
    'smtpd_error_sleep_time' => '3',
    'smtp_destination_concurrency_limit' => '4',
    'smtpd_hard_error_limit' => '10',
    'smtpd_recipient_limit' => '1000',
    'smtpd_sender_restrictions' =>
      'reject_unknown_sender_domain, hash:/etc/postfix/access',
    'smtpd_soft_error_limit' => '5',
    'smtpd_timeout' => '120s',
    'smtp_sasl_auth_enable' => nil,
    'smtp_sasl_mechanism_filter' => nil,
    'smtp_sasl_password_maps' => nil,
    'transport_maps' => nil,
    'unknown_local_recipient_reject_code' => '450',
    'virtual_maps' => nil,
    # Postfix will interpret this to be hostname
    'smtp_helo_name' => '$myhostname',
  },
  # master.cf as per http://www.postfix.org/master.5.html
  # In master.cf, unique by service:type and not just service.
  'master.cf' => {
    'anvil' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '1',
        'command' => 'anvil',
      },
    },
    'bounce' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '0',
        'command' => 'bounce',
      },
    },
    'cleanup' => {
      'unix' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '0',
        'command' => 'cleanup',
      },
    },
    'defer' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '0',
        'command' => 'bounce',
      },
    },
    'discard' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'discard',
      },
    },
    'error' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'error',
      },
    },
    'flush' => {
      'unix' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '1000?',
        'maxproc' => '0',
        'command' => 'flush',
      },
    },
    'lmtp' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'lmtp',
      },
    },
    'local' => {
      'unix' => {
        'private' => '-',
        'unpriv' => 'n',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'local',
      },
    },
    'pickup' => {
      'fifo' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '60',
        'maxproc' => '1',
        'command' => 'pickup',
      },
    },
    'proxymap' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'proxymap',
      },
    },
    'proxywrite' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '1',
        'command' => 'proxymap',
      },
    },
    'qmgr' => {
      'fifo' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '300',
        'maxproc' => '1',
        'command' => 'qmgr',
      },
    },
    'relay' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'smtp -o smtp_fallback_relay=',
      },
    },
    'retry' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'error',
      },
    },
    'rewrite' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'trivial-rewrite',
      },
    },
    'scache' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '1',
        'command' => 'scache',
      },
    },
    'showq' => {
      'unix' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'showq',
      },
    },
    'smtp' => {
      'inet' => {
        'private' => 'n',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'smtpd',
      },
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'smtp',
      },
    },
    'tlsmgr' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '1000?',
        'maxproc' => '1',
        'command' => 'tlsmgr',
      },
    },
    'trace' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '0',
        'command' => 'bounce',
      },
    },
    'verify' => {
      'unix' => {
        'private' => '-',
        'unpriv' => '-',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '1',
        'command' => 'verify',
      },
    },
    'virtual' => {
      'unix' => {
        'private' => '-',
        'unpriv' => 'n',
        'chroot' => 'n',
        'wakeup' => '-',
        'maxproc' => '-',
        'command' => 'virtual',
      },
    },
  },
  'mynetworks' => [
    '127.0.0.1/32',
    '[::1]/128',
  ],
  'relaydomains' => [],
  'sasl_auth' => {},
  'sasl_passwd' => {},
  'transport' => {},
  'virtual' => {},
  'custom_headers' => {},
}
