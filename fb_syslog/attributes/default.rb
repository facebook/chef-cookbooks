# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

# Add in some reasonable defaults for all syslog.confs
default['fb_syslog'] = {
  'syslog-entries' => {
    'base_messages' => {
      # Will commentify comments later
      'comment' => 'Log anything info level or higher. A lot ' +
                   'of things go into their own file.',
      'selector' => '*.info;mail,authpriv,cron,' +
                    'local2,local3,local5,local6.none',
      'action' => '-/var/log/messages',
    },
    'mail' => {
      'comment' => 'Log all the mail messages in one place.',
      'selector' => 'mail.*',
      'action' => '-/var/log/maillog',
    },
    'cron' => {
      'comment' => 'Log all cron messages in one place.',
      'selector' => 'cron.*',
      'action' => '-/var/log/cron',
    },
    'emergency' => {
      'comment' => 'Everybody gets emergency messages',
      'selector' => '*.emerg',
      'action' => '*',
    },
    'news' => {
      'comment' => 'Save news errors of level crit and higher ' +
                   'in a special file.',
      'selector' => 'uucp,news.crit',
      'action' => '-/var/log/spooler',
    },
    'boot' => {
      'comment' => 'Among other places, boot messages always go to boot.log',
      'selector' => 'local7.*',
      'action' => '-/var/log/boot.log',
    },
  },
  'rsyslog_server' => false,
  'rsyslog_rulesets' => {},
  'rsyslog_nonruleset_ports' => {},
  'rsyslog_early_lines' => [],
  'rsyslog_late_lines' => [],
  'rsyslog_additional_sockets' => [],
  'rsyslog_facilities_sent_to_remote' => [],
  'rsyslog_port' => '514',
  'rsyslog_upstream' => '',
  'rsyslog_relp_tls' => false,
  'sysconfig' => {
    'vars' => {
      'SYSLOGD_OPTIONS' => '',
    },
    'extra_lines' => [],
  },
}
