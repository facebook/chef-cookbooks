fb_hostconf Cookbook
====================
This cookbook configures host.conf and provides an API for modifying all 
aspects of host.conf

Requirements
------------

Attributes
----------
* node['fb_hostconf']['trim']
* node['fb_hostconf']['multi']
* node['fb_hostconf']['nospoof']
* node['fb_hostconf']['spoofalert']
* node['fb_hostconf']['spoof']
* node['fb_hostconf']['reorder']
* node['fb_hostconf']['order']

Usage
-----
Will take arbirtrary values under `node['fb_hostconf']` and write them out
to /etc/host.conf in different ways depending on the name of key or datatype 
of the value.

If key name is 'spoof' or 'trim', the value is written out as is without 
validation

If datatype of the value is an Array the values will be written out as 
comma seperated strings

All other values are interpeted as boolean and if evaluated to true, the 
string 'on' is written out else 'off' is written out.

See man host.conf for all settable attributes

The default is

    default['fb_hostconf']['multi'] = True
