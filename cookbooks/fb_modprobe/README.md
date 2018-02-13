fb_modprobe Cookbook
====================

Requirements
------------

Attributes
----------
* node['fb_modprobe']['extra_entries']
* node['fb_modprobe']['modules_to_load_on_boot']

Usage
-----
Add things to `node['fb_modprobe']['extra_entries']` to have them added to
`/etc/modprobe.d/fb_modprobe.conf`.

Add things to `node['fb_modprobe']['modules_to_load_on_boot']` to have them
added to either `/etc/sysconfig/modules` or `/etc/modules-load.d/chef.conf`
depending on whether you're on systemd or not.

### Methods
The following methods are provided

* `FB::Modprobe.supports_ipv6_autoconf_param`
Returns true if autoconf is a valid option to the ipv6 parameter.

* `FB::Modprobe.module_initialized?`
Returns true if the modules is initialized - this will work for both built-in
and module drivers.

* `FB::Modprobe.module_loaded?`
Checks if a module is loaded - a more naive version of the above method.

### fb_modprobe_module

Loading and unloading modules can be managed using `fb_modprobe_module`
resource.

Properties:
* `module_name` - Name of the module to be loaded/unloaded (required)
* `verbose` - Pass `-v` to modprobe (so make it verbose) (default: False)
* `timeout` - Command timeout (default: 300)
* `fallback` - When unloading, fallback to `rmmod` if modprobe fails (modprobe
  can fail for various reasons, including the module being uninstalled before
  being unloaded) (default: False)
* `module_params` - Optional parameters to pass when loading the module
