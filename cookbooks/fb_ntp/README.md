fb_ntp Cookbook
====================
This cookbook configures NTPD on a system.

Requirements
------------

Attributes
----------
* node['fb_ntp']['ntpd_options']
* node['fb_ntp']['ntpdate_options']
* node['fb_ntp']['ntpdate_retries']
* node['fb_ntp']['sync_hwclock']
* node['fb_ntp']['ntp_conf_server_options']
* node['fb_ntp']['preferred_servers']
* node['fb_ntp']['servers']
* node['fb_ntp']['noselect_servers']
* node['fb_ntp']['listen_interfaces']
* node['fb_ntp']['monitor']
* node['fb_ntp']['leapfile']
* node['fb_ntp']['leapsmearinterval']

Usage
-----
All the attributes will be populated by sane defaults and you shouldn't normally
need to set any of them.

`node['fb_ntp']['servers']` is an array of server that ntpd and ntpdate will
use. `node['fb_ntp']['preferred_servers']` is the same but the servers
defined there will be marked as "preferred" by ntpd.
`node['fb_ntp']['noselect_servers']` is an array of server that are only used
for display and are discarded by the selection algorithm.
`node['fb_ntp']['ntpd_options']` and `node['fb_ntp']['ntpdate_options']`
are the command line options passed respectively to ntpd and ntpdate. Finally,
`node['fb_ntp']['ntpdate_retries']` is number of retries ntpdate init script
tries to setup correct time on bootup.
`node['fb_ntp']['sync_hwclock']` is a boolean that controls whether we try
to sync the hardware clock after a successful ntpdate run on boot.
`node['fb_ntp']['ntp_conf_server_options']` is a string that will be appended
to all server lines in the ntp configuration file.
`node['fb_ntp']['listen_interfaces']` is an array of interface to limit ntp
to listen to.
`node['fb_ntp']['monitor']` when set to false disables the monlist feature which
can be used as a reflection DDOS (CVE-2013-5211).
`node['fb_ntp']['leapfile']` should be set only on Stratum 2 servers.
Contains an actual copy of [IETF Leap Seconds file](https://www.ietf.org/timezones/data/leap-seconds.list)
The file should be updated twice a year. We will get notification in
ntp-notify@fb.com mailing list before it happens, and you will need to update
this file in the cookbook. If you want to add fake leap second for testing or
debug purposes, you will can use 'ntpchkng utils fakeseconds' to generate
fake leap seconds and update checksums in this file. Make sure that
the production version of the file contains only real leap seconds!
`node['fb_ntp']['leapsmearinterval']` should be set only on Stratum 2 servers.
Duration of time in seconds for smearing of the leap second offset.

Default recipe is included in fb_init, whereas the server one has to be included
in the runlist in roles definition. Usually only cm and routablecm tiers will
need it.
