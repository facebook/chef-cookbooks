fb_apcupsd Cookbook
====================
This cookbook installs and configures apcupsd, the APC UPS Power Management
daemon and its web interface.

Requirements
------------

Attributes
----------
* node['fb_apcupsd']['config']
* node['fb_apcupsd']['enable']
* node['fb_apcupsd']['hosts']

Usage
-----
### Daemon
Include `fb_apcupsd::default` to install apcupsd. The daemon is enabled and 
started by default; this can be controlled with `node['fb_apcupsd']['enable']`.
The daemon is configured via the `node['fb_apcupsd']['config']` attribute, 
which will be used to render the main configuration file at 
`/etc/apcupsd/apcupsd.conf`. Please refer to the 
[upstream documentation](http://www.apcupsd.org/manual/manual.html#configuration-directive-reference) 
for the available options. The default configuration mimics the upstream Debian
 settings and is listed in the [attributes file](attributes/default.rb). This 
configuration will autodetect any USB-connected UPS devices and monitor them; 
it will also activate the network management service on port `3551` and bind it
to `localhost`.

### Frontend
Include `fb_apcupsd::frontend` to install the acpupsd web interface. This is 
composed of a number of CGI programs (multimon, upsaccess, upsstats, upsfstats,
 upsimage), that can monitor a number of different local and remote UPS devices.
To this end, use the `node['fb_apcupsd']['hosts']` to define what should be 
monitored; this defaults to `localhost`. Example:

    node.default['fb_apcupsd']['hosts']['192.168.0.1'] = 'Web server UPS'

Note that this recipe will not install or configure a web server, so unless you
set one up the CGI will not actually be available.
