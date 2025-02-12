default['fb_cyrus'] = {
  'manage_packages' => true,
  'configs' => {
    'cyrus' => {
      'START' => {
        'recover' => {
          'cmd' => '/usr/sbin/cyrus ctl_cyrusdb -r',
        },
        'idled' => {
          'cmd' => 'idled',
        },
        'delprune' => {
          'cmd' => '/usr/sbin/cyrus expire -E 3',
        },
        'tlsprune' => {
          'cmd' => '/usr/sbin/cyrus tls_prune',
        },
        'deleteprune' => {
          'cmd' => '/usr/sbin/cyrus expire -E 4 -D 28',
          'at' => '0430',
        },
        'expungeprune' => {
          'cmd' => '/usr/sbin/cyrus expire -E 4 -X 28',
          'at' => '0445',
        },
      },
    'SERVICES' => {
      # required for admin services, but force to listen
      # on localhost
      'imap' => {
        'cmd' => 'imapd -U 30',
        'listen' => 'localhost:imap',
        'prefork' => 0,
        'maxchild' => 100,
      },
      'imaps' => {
        'cmd' => 'imapd -s -U 30',
        'listen' => 'imaps',
        'prefork' => 1,
        'maxchild' => 100,
      },
      'lmtpunix' => {
        'cmd' => 'lmtpd',
        'listen' => '/run/cyrus/socket/lmtp',
        'prefork' => 0,
        'maxchild' => 20,
      },
      'sieve' => {
        'cmd' => 'timsieved',
        'listen' => 'localhost:sieve',
        'prefork' => 0,
        'maxchild' => 100,
      },
      'notify' => {
        'cmd' => 'notifyd',
        'listen' => '/run/cyrus/socket/notify',
        'proto' => 'udp',
        'prefork' => 1,
      },
    },
    'EVENTS' => {
      'checkpoint' => {
        'cmd' => '/usr/sbin/cyrus ctl_cyrusdb -c',
        'period' => 30,
      },
      'delprune' => {
        'cmd' => '/usr/sbin/cyrus expire -E 3',
        'at' => '0401',
      },
      'tlsprune' => {
        'cmd' => '/usr/sbin/cyrus tls_prune',
        'at' => '0401',
      },
      'squatter1' => {
        'cmd' => '/usr/bin/ionice -c idle /usr/lib/cyrus/bin/squatter -i',
        'period' => 120,
      },
      'squattera' => {
        'cmd' => '/usr/lib/cyrus/bin/squatter',
        'at' => '0517',
      },
    },
    },
    'imapd' => {
      'configdirectory' => '/var/lib/cyrus',
      'proc_path' => '/run/cyrus/proc',
      'mboxname_lockpath' => '/run/cyrus/lock',
      'defaultpartition' => 'default',
      'partition-default' => '/var/spool/cyrus/mail',
      'partition-news' => '/var/spool/cyrus/news',
      'newsspool' => '/var/spool/news',
      'altnamespace' => 'yes',
      'unixhierarchysep' => 'no',
      'lmtp_downcase_rcpt' => 'yes',
      'admins' => 'cyrus',
      'allowanonymouslogin' => 'no',
      'popminpoll' => 0,
      'autocreate_quota' => 0,
      'umask' => '077',
      'sieveusehomedir' => 'false',
      'sievedir' => '/var/spool/sieve',
      'httpmodules' => 'caldav carddav',
      'hashimapspool' => 'true',
      'allowplaintext' => 'no',
      'sasl_pwcheck_method' => 'auxprop',
      'sasl_auxprop_plugin' => 'sasldb',
      'sasl_auto_transition' => 'no',
      'tls_client_ca_dir' => '/etc/ssl/certs',
      'tls_session_timeout' => 1440,
      'lmtpsocket' => '/run/cyrus/socket/lmtp',
      'idlesocket' => '/run/cyrus/socket/idle',
      'notifysocket' => '/run/cyrus/socket/notify',
      'syslog_prefix' => 'cyrus',
      'debug' => 'yes',
    },
  },
}
