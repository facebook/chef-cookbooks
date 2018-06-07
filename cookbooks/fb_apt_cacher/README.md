fb_apt_cacher Cookbook
====================
This cookbook installs and configures Apt-Cacher NG, caching proxy server for
software repositories.

Requirements
------------

Attributes
----------
* node['fb_apt_cacher']['config']
* node['fb_apt_cacher']['security']
* node['fb_apt_cacher']['sysconfig']

Usage
-----
Include `fb_apt_cacher` in your runlist to install Apt-Cacher NG. Configuration
can be customized using `node['fb_apt_cacher']['config']` according to the
[upstream
documentation](https://www.unix-ag.uni-kl.de/~bloch/acng/html/index.html).
Please refer to the [attributes file](attributes/default.rb) for the default
settings, which mimic upstream Debian defaults. Additional configuration is
available via the `node['fb_apt_cacher']['security']` attribute, which will be
rendered into a separate config file with restricted permissions. This is useful
to set things like access credentials, for example:

```ruby
node.default['fb_apt_cacher']['security']['AdminAuth'] = 'admin:secret'
```

Finally, the startup environment can be customized using the
`node['fb_apt_cacher']['sysconfig']` attribute.
