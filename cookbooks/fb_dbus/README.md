fb_dbus Cookbook
=====================
Installs and configures dbus

Requirements
------------

Attributes
----------
* node['fb_dbus']['implementation']
* node['fb_dbus']['manage_packages']
* node['fb_dbus']['manage_dbus_tools']
* node['fb_dbus']['reboot_required']

Usage
-----
Just include `fb_dbus` in your runlist. Set `node['fb_dbus']['implementation']`
to the dbus implementation you'd like to use (`dbus-daemon` or `dbus-broker`).
Switching implementations will require a reboot; if reboots are allowed and
`node['fb_dbus']['reboot_required']` is true, Chef will effect the reboot,
otherwise an alarm will be raised. `fb_dbus` will install the appropriate
packages for the implementation you chose, unless you set
`node['fb_dbus']['manage_packages']` to false. If you set
`node['fb_dbus']['manage_dbus_tools']` to true this recipe will also manage
the installation of dbus-tools, which is something you should do if your
recipe uses the `dbus-send` command.
