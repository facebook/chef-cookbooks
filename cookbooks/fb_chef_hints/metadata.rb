# Copyright (c) 2020-present, Facebook, Inc.
name 'fb_chef_hints'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Attribute hints logic implementation'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# never EVER change this number, ever.
version '0.1.0'
depends 'fb_helpers'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'mac_os_x'
supports 'ubuntu'
supports 'windows'
