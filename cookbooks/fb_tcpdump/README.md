fb_tcpdump Cookbook
================
Installs tcpdump - a data-network packet analyzer computer program that runs
under a command line interface - and keeps it up to date.
Not supported on non-Linux systems, or for distros
where the tcpdump package is unavailable.

Requirements
------------

Attributes
----------
* node['fb_tcpdump']['manage_packages']

Usage
-----
#### fb_tcpdump::default
Just include the recipe in your runlist.

### Packages
By default this cookbook keeps the tcpdump package up-to-date, but if you
want to manage them locally, simply set
`node['fb_tcpdump']['manage_packages']` to false.
