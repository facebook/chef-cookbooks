fb_cyrus Cookbook
=================

Requirements
------------

Attributes
----------
* node['fb_cyrus']['manage_packages']
* node['fb_cyrus']['configs']['cyrus'][$SERVICE][$CONFIG]
* node['fb_cyrus']['configs']['imapd'][$KEY]

Usage
-----

### Packages

This cookbook will install the necessary packages and keep them up-to-date.  If
you don't want that, you can set `node['fb_cyrus']['manage_packages']` to
`false`.

Note that this cookbook only sets up the `imapd` services and thus only
installs the core, administrative, and imap packages - it does not install or
setup pop3 or nntp at this time.

### Configuration

The default configuration for cyrus.conf is in
`node['fb_cyrus']['configs']['cyrus']`, and you can easily add to it. For
example, to enable pop3, you could do:

```ruby
node.default['fb_cyrus']['configs']['cyrus']['SERVICES']['pops3'] = {
  ...
}
```

The configuration for imapd.conf is in `node['fb_cyrus']['configs']['imapd']`,
and you can easily add your certificates with:

```ruby
node.default['fb_cyrus']['configs']['imapd']['tls_server_cert'] = '...'
node.default['fb_cyrus']['configs']['imapd']['tls_server_key'] = '...'
```
