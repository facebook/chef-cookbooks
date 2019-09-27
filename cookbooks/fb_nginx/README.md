fb_nginx Cookbook
=================
Setup nginx

Requirements
------------
On Fedora/RHEL/CentOS, this requires EPEL.

Attributes
----------
* node['fb_nginx']['enable']
* node['fb_nginx']['config']
* node['fb_nginx']['config'][$CONFIG]
* node['fb_nginx']['sites']
* node['fb_nginx']['sites'][$NAME]
* node['fb_nginx']['sysconfig']
* node['fb_nginx']['sysconfig'][$CONFIG]
* node['fb_nginx']['modules']

Usage
-----
This cookbook setups and runs nginx for you.

### Sites
Each site is configured with a name which is used mostly to modify the node object later int he run, but also as a comment in the rendered config.

Each key in the sites hash can have a value of the following types:

* String - gets rendered as `#{key} #{value}`
* Array - gets rendered as `#{key} #{value.join(' ')}`
* Hash - the name is used to start a new block, and the nested hash is rendered
  similarly to the outer hash.

It is important to note that keys that are repeated need their modifier to be
part of the key, i.e. "location /" and "location /foo"

For example:

```ruby
node.default['fb_nginx']['sites']['test_site'] = {
  'listen 443' => 'ssl default_site'
  'listen [::]:443]' => 'ssl default_site',
  'server_name' => 'test.example.com',
  'ssl_certificate' => '/etc/nginx/test.example.com.crt',
  'ssl_certificate_key' => '/etc/nginx/test.example.com.key',
  'location /' => {
    'proxy_pass' => 'http://localhost:8080',
    'proxy_set_header Host' => '$host',
    'proxy_set_header X-Forwarded-Proto' => 'https',
    'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
    'proxy_set_header X-Real-Ip' => '$remote_addr',
  },
}
```

Would be rendered like so:

```
server {
  listen 443 ssl default_server;
  listen [::]:443 ssl default_server;
  server_name test.example.com
  ssl_certificate /etc/nginx/test.example.com.crt;
  ssl_certificate_key /etc/nginx/test.example.com.key;
  location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-Ip $remote_addr;
  }
}
```

Note there is a special `_create_self_signed_cert` setting you can put on any
site and if it's set, and if no certificate is found, `fb_nginx` will create a
self-signed cert for you.

### enabled
When enabled is set to false, the server will be shutdown, but the config
file will still be rendered.

### config
`config` works similarly to `sites`, but is meant to be in a top-level config file to configure things like `events` or the `http` subsystem.

For example, you may do:

```ruby
node.default['fb_nginx']['config']['events'] = {
  'multi_accept' => 'on',
}
```

Which would render like:

```
events {
  multi_accept on
}
```

Like in `sites`, the value can be a string, array, or hash and will be handled the same way.

### modules
The `modules` entry is simply an array of modules to load. They are assumed to be in the 'modules' directory and end with a `.so`. In other words:

```ruby
node.default['fb_nginx']['modules'] = ['ngx_http_geoip_module']
```

Would render as:

```
load_module modules/ngx_http_geoip_module.so
```

### sysconfig
The `sysconfig` populates the variables that the init script or systemd unit reads (in `/etc/sysconfig` or `/etc/default` depending on your distro). This one is a simple 1-layer hash that is rendered as shell-readable key-value pairs. All keys are upcased. Thus:

```ruby
node.default['fb_nginx']['sysconfig']['ulimit'] = '-n 4096'
```

will render as:

```
ULIMIT="-n 4096"
```
