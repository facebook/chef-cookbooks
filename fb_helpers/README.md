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

* `node.yocto?`
    Is a Yocto platform

* `node.systemd?`
    True if the node uses systemd as their init system.

* `node.container?`
    True if the node is in a container.

* `node.virtual?`
    Is a guest.

### FB::Helpers
The following methods are available:

*  `FB::Helpers.commentify(comment, arg)`
    Commentify takes the string in `comment` and wraps it appropriately
    for being a comment. By default it'll comment it ruby-style (leading "# ")
    with a width of 80 chars, but the arg hash can specify `start`, `finish`,
    and `width` to adjust it's behavior.
