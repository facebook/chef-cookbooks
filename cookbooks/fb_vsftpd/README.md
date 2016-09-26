fb_vsftpd Cookbook
====================
This cookbook installs and configures vsftpd, the lightweight FTP server.

Requirements
------------

Attributes
----------
* node['fb_vsftpd']['config']
* node['fb_vsftpd']['enable']
* node['fb_vsftpd']['ftpusers']
* node['fb_vsftpd']['user_list']

Usage
-----
Include `fb_vsftpd::default` to install vsftpd. The daemon is enabled and 
started by default; this can be controlled with `node['fb_vsftpd']['enable']`.
The daemon is configured via the `node['fb_vsftpd']['config']` attribute, 
which will be used to render the main configuration file `vsftpd.conf`. Please
refer to the
[upstream documentation](http://vsftpd.beasts.org/vsftpd_conf.html)
for the available options. The default configuration mimics the upstream Debian
settings and is listed in the [attributes file](attributes/default.rb). Use the
`node['fb_vsftpd']['ftpusers']` to control which users will be denied access at
PAM stage. Use `node['fb_vsftpd']['user_list']` to populate the vsftpd user
list, which by default is the same as ftpusers and set to deny mode.
