fb_helpers Cookbook
===================
Node helper methods for Facebook open-source cookbooks.

Requirements
------------

Attributes
----------

Usage
-----
### node methods
Simply depend on this cookbook from your metadata.rb to get these methods in
your node.

* `node.centos?`
    Is CentOS

* `node.centos5?`
    Is CentOS5

* `node.centos6?`
    Is CentOS6

* `node.centos7?`
    Is CentOS7

* `node.debian?`
    Is Debian

* `node.ubuntu?`
    Is Ubuntu

* `node.linux?`
    Is Linux

* `node.macosx?`
    Is Mac OS X

* `node.windows?`
    Is Windows

* `node.yocto?`
    Is a Yocto platform

* `node.systemd?`
    True if the node uses systemd as their init system.

* `node.container?`
    True if the node is in a container.

* `node.virtual?`
    Is a guest.

* `node.efi?`
    Is an EFI machine

* `node.device_of_mount(m)`
   Take a string representing a mount point, and return the device it resides 
   on.

### FB::Helpers
The following methods are available:

*  `FB::Helpers.commentify(comment, arg)`
    Commentify takes the string in `comment` and wraps it appropriately
    for being a comment. By default it'll comment it ruby-style (leading "# ")
    with a width of 80 chars, but the arg hash can specify `start`, `finish`,
    and `width` to adjust it's behavior.
*  `FB::Version.new(version)`
   Helper class to compare software versions. Sample usage:

      FB::Version.new('1.3') < FB::Version.new('1.21')
      => true
      FB::Version.new('4.5') < FB::Version.new('4.5')
      => false
      FB::Version.new('3.3.10') > FB::Version.new('3.4')
      => false
      FB::Version.new('10.2') >= FB::Version.new('10.2')
      => true
      FB::Version.new('1.2.36') == FB::Version.new('1.2.36')
      => true
      FB::Version.new('3.3.4') <= FB::Version.new('3.3.02')
      => false
