fb_apache Cookbook
==================
Installs and configures Apache

Requirements
------------
Currently only tested on Linux

Attributes
----------
* node['fb_apache']['manage_packages']
* node['fb_apache']['sites'][$SITE][$CONFIG][$VALUE]

Usage
-----
### Packages
My default `fb_apache` will install and keep up to date the apache and mod_ssl packages as relevant for your distribution. If you'd prefer to do this on your own then you can set `node['fb_apache']['manage_packages']` to false.

### Sites / VirtualHosts
The `node['fb_apache']['sites']` hash configures virtual hosts. All virtual hosts are kept in a single file called `fb_apache_sites.cfg` in a directory relevant to your distribution. In general, it's a 1;1 mapping of the apache syntax to a hash. So for example:

```ruby
node.default['fb_apache']['sites']['*:80'] = {
  'ServerName' => 'example.com',
  'ServerAdmin' => 'l33t@example.com',
  'DocRoot' => '/var/www',
}
```

Will produce:

``
<VirtualHost *:80>
  ServerName example.com
  ServerAdmin l33t@example.com
  Docroot /var/www
</VirtualHost>
```

If the value of the hash is an Array, then it's assumed it's a key that can be repeated. So for example:

```ruby
node.default['fb_apache']['sites']['*:80'] = {
  'ServerAlias' => [
    'cool.example.com',
    'awesome.example.com',
  ]
}
```

Would produce:

``
<VirtualHost *:80>
  ServerAlias cool.example.com
  ServerAlias awesome.example.com
</VirtualHost>
```

This can be used for anything which repeats such as `Alias`, `ServerAlias`, or `ScriptAlias`.

If the value is a hash, then the key is treated like another markup tag in the config and the hash is values inside that tag. For example:


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

Note that you have to include the entire tag here (`Directory /var/www`, instead of just `Directory`).

Hashes like this work for all nested tags such as `Directory` and `Location`.

#### Rewrite rules

One exception to this generic 1:1 mapping is rewrite rules. Because of the complicated nature of rewrite rules and because they are not structured like most of Apache VirtualHost configuration, these are special-cased in this cookbook. These can be stored in the special `_rewrites` key in the hash. Since multiple conditions can be mapped to a given rule for ease of reading and conciseness, the API here is a mappig of **rules** to **list of conditions** (which is the opposite order they'd come in the actual config). So for example:

```
node.default['fb_apache']['sites']['*:80'] = {
  '_rewrites' => {
    '^/(.*) https://www.example.com/real_site/$1' => [
      '%{REQUEST_URI} ^/old_thing',
      '%{REQUEST_URI} ^/other_old_thing',
    ]
  }
}
```

Would produce:

```
<VirtualHost *:80>
  RewriteCond %{REQUEST_URI} ^/old_thing
  RewriteCond %{REQUEST_URI} ^/other_old_thing
  RewriteRule ^/(.*) https://www.example.com/real_site/$1
</VirtualHost>
```
