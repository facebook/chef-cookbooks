fb_consul Cookbook
==================
Manages a consul instance

Requirements
------------

Attributes
----------
* node['fb_consul']['enable']
* node['fb_consul']['config']
* node['fb_consul']['services']
* node['fb_consul']['checks']
* node['fb_consul']['certificate_cookbook']

Usage
-----
By including 'fb_consul::default', you will get a default config for a consul
agent.

If you use `fb_iptables`, the default recipe also adds the relevant rules for
the agent to work. To run a server you can include `fb_consul::server_fw` to
get the right firewall rules there as well.

You can configure it with the following attributes.

### enable

If you would like to include the cookbook but disable the service, you can set
`enable` to `false`.

### config

This cookbook uses the configuration file to configure the agent, instead of
command-line options. Everything you can pass on the command-line can be
specified in configuration files, but sometimes the name of the option is
slightly different. See the **Configuration Files** section of [this
page](https://www.consul.io/docs/agent/options.html).

Here's an example:

```ruby
{
  'server' => true,
  'bind_addr' => '1.2.3.4',
  'bootstrap_expect' => 3,
}.each do |key, val|
  node.default['fb_consul']['config'][key] = val
end
```

Run `consul agent --help` for a full list of options.

**NOTE**: You **may not** pass `config-file` or `config-dir`.

### services

You can define static consul services using the `services` hash. The format is
identical to the [services
definition](https://www.consul.io/docs/agent/services.html), however you don't
need to specify name, we will use the key in the hash and populate it for you
(unless you specify one). For example:

```ruby
node.default['fb_consul']['services']['myservices'] = {
  'port' => 12345,
}
```

### checks

You can define static checks using the `checks` hash. The format is identical
to the [checks definition](https://www.consul.io/docs/agent/checks.html),
however you don't need to specify a name, we will use the key in the hash and
populate it for you (unless you specify one). For example:

```ruby
node.default['fb_consul']['checks']['mycheck'] = {
  'args' => ['/bin/check_mem', '-limit', '256MB'],
  'interval' => '5s',
}
```

### Certificates

This cookbook will make setting up TLS simple, but assumes you are using
`auto_encrypt`.

If `certificate_cookbook` is defined, then this cookbook will do several things:

* On all agents, copy `consul-agent-ca.pem` to `/etc/consul` as well as modify
  the config onall agents to include `ca_file` to point to it.
* On all servers, copy `consul-agent-ca.pem`, `consul-agent-ca-key.pem` to
  `/etc/consul`, and update the config to include `ca_file` to poitn to it.
* On all servers, copy `consul-server-<HOSTNAME>.pem` and
  `consul-server-key-<HOSTNAME>.pem` to `/etc/consul/consul-server{-key}.pem`
  and update the config to include `cert_file` and `key_file` to point
  to them.

So to setup TLS, you'll want to, on some server, do:

```shell
consul tls ca create
```

and put the resulting keypair into a relevant cookbook's `files` directory.

Then for every server in your cluster, do:

```shell
consul tls cert create -server
```

And put the resulting keypair into the same cookbook's `files` directory,
but named with the hostname in them (`consul-server-key-<HOSTNAME>.pem`).

You will then want to make sure you set your `auto_encrypt` settings along
with any `verify_*` settings you wish.
