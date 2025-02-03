default['fb_grafana'] = {
  'config' => {
    'paths' => {
      'data' => '/var/lib/grafana',
      'logs' => '/var/log/grafana',
      'plugins' => '/var/lib/grafana/plugins',
    },
    'server' => {
      'protocol' => 'https',
      'http_port' => 3000,
    },
  },
  'gen_selfsigned_cert' => false,
  'plugins' => {},
  'datasources' => {},
  'version' => nil,
}
