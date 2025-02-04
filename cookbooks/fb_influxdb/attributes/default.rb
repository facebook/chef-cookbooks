default['fb_influxdb'] = {
  'manage_packages' => true,
  'config' => {
    'reporting-enabled' => false,
    'meta' => {
      'dir' => '/var/lib/influxdb/meta',
    },
    'data' => {
      'dir' => '/var/lib/influxdb/data',
      'wal-dir' => '/var/lib/influxdb/wal',
    },
    'coordinator' => {},
    'retention' => {},
    'shard-precreation' => {},
    'monitor' => {},
    'http' => {
      'bind-address' => 'localhost:8086',
    },
    'ifql' => {},
    'logging' => {},
    'subscriber' => {},
    # note a typo, some sections should be rendered as [[ ]]
    '[graphite]' => {},
    '[collectd]' => {
      'enabled' => true,
      'bind-address' => '127.0.0.1:25826',
      'database' => 'collectd',
      'typesdb' => '/usr/share/collectd',
      'security-level' => 'none',
    },
    '[opentsdb]' => {},
    '[udp]' => {},
    'continuous_queries' => {},
    'tls' => {},
  },
}
