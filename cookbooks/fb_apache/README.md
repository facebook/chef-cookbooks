fb_apache Cookbook
==================
Installs and configures Apache

Requirements
------------

Attributes
----------
* node['fb_apache']['manage_packages']
* node['fb_apache']['sites'][$SITE][$CONFIG]
* node['fb_apache']['sysconfig'][$KEY]
* node['fb_apache']['sysconfig']['_extra_lines']
* node['fb_apache']['modules']
* node['fb_apache']['modules_directory']
* node['fb_apache']['modules_mapping']
* node['fb_apache']['module_packages']

Usage
-----
### Packages
My default `fb_apache` will install and keep up to date the `apache` and 
`mod_ssl` packages as relevant for your distribution. If you'd prefer to do 
this on your own then you can set `node['fb_apache']['manage_packages']` to 
`false`.

For modules, we keep a mapping of the package required for modules in
`node['fb_apache']['module_packages']`. If `manage_packages` is enabled, we will
install the relevant packages for any modules you enable in
`node['fb_apache']['modules']`. This is important since it'll happen before we
attempt to start apache.

### Sites / VirtualHosts
The `node['fb_apache']['sites']` hash configures virtual hosts. All virtual 
hosts are kept in a single file called `fb_apache_sites.cfg` in a directory 
relevant to your distribution. In general, it's a 1:1 mapping of the apache 
syntax to a hash. So for example:

```ruby
node.default['fb_apache']['sites']['*:80'] = {
  'ServerName' => 'example.com',
  'ServerAdmin' => 'l33t@example.com',
  'DocRoot' => '/var/www',
}
```

Will produce:

```
<VirtualHost *:80>
  ServerName example.com
  ServerAdmin l33t@example.com
  Docroot /var/www
</VirtualHost>
```

If the value of the hash is an `Array`, then it's assumed it's a key that can 
be repeated. So for example:

```ruby
node.default['fb_apache']['sites']['*:80'] = {
  'ServerAlias' => [
    'cool.example.com',
    'awesome.example.com',
  ]
}
```

Would produce:

```
<VirtualHost *:80>
  ServerAlias cool.example.com
  ServerAlias awesome.example.com
</VirtualHost>
```

This can be used for anything which repeats such as `Alias`, `ServerAlias`, or 
`ScriptAlias`.

If the value is a hash, then the key is treated like another markup tag in the 
config and the hash is values inside that tag. For example:


```
node.default['fb_apache']['sites']['*:80'] = {
  'Directory /var/www' => {
    'Options' => 'Indexes FollowSymLinks MultiViews',
    'AllowOverride' => 'all',
    'Order' => 'allow,deny',
  }
}
```

Would produce:

```
<VirtualHost *:80>
  <Directory /var/www>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride all
    Order allow,deny
  </Directory>
</VirtualHost>
```

Note that you have to include the entire tag here (`Directory /var/www`, 
instead of just `Directory`).

Hashes like this work for all nested tags such as `Directory` and `Location`.

#### Rewrite rules

One exception to this generic 1:1 mapping is rewrite rules. Because of the 
complicated nature of rewrite rules and because they are not structured like 
most of Apache VirtualHost configuration, these are special-cased in this 
cookbook. These can be stored in the special `_rewrites` key in the hash. Each 
conditional/rewrite set is an entry in the hash. The key is a human-readable 
name (will be used as a comment) and the value is another hash with a 
"conditions" array and a "rule" array. Note that you just like conditionals in 
apache, multiple conditionals in the same block will be ANDed together. To get 
OR, make an additional entry in the hash. So for example:

```
node.default['fb_apache']['sites']['*:80'] = {
  '_rewrites' => {
    'rewrite old thing to new thing' => {
      'conditions' => [
        '%{REQUEST_URI} ^/old_thing',
        '%{REQUEST_URI} ^/other_old_thing',
      ],
      'rule' => '^/(.*) https://www.example.com/real_site/$1',
    }
  }
}
```

Would produce:

```
<VirtualHost *:80>
  # rewrite old thing to new thing
  RewriteCond %{REQUEST_URI} ^/old_thing
  RewriteCond %{REQUEST_URI} ^/other_old_thing
  RewriteRule ^/(.*) https://www.example.com/real_site/$1
</VirtualHost>
```

### Sysconfig / Defaults
`node['fb_apache']['sysconfig']` can be used to configure either
`/etc/sysconfig/httpd` on Redhat-like systems or `/etc/default/apache2` on
Debian-like systems.

By default the key-value pairs in the hash are mapped to KEY="value" pairs in
the file (the keys are up-cased and values are enclosed in quotes) with two
exceptions:

* If the value is an array, it is joined on strings. We preset `options` (RHEL)
  and `htcacheclean_options` (Debian) to empty arrays for convenience
* If the key is `_extra_lines`, see below.

`node['fb_apache']['sysconfig']['_extra_lines']` is an array and every line in
it is put at the end of the file verbatim.

### Modules
The list of modules in `node['fb_apache']['modules']` (which is an array) are
all `LoadModule`d in `fb_modules.conf`. No config is done for them, as that
should be done using `node['fb_apache']['extra_configs']`.

Modules in there should not include the `_module` suffix.

The mapping of names to files is held in `node['fb_apache']['modules_mapping']`
and we've pre-populated all the common modules on both distro variants.

Finally, `node['fb_apache']['modules_directory']` is set to the proper module
directory for your distro, but you may override it if you'd like.

### Extra Configs
Everything in `node['fb_apache']['extra_configs']` will be converted from hash
syntax to Apache Config syntax in the same 1:1 manner as the `sites` hash above
and put into an `fb_apache.conf` config file.
