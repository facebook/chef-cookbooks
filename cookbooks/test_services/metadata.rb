# Copyright (c) 2018-present, Facebook, Inc.
name 'test_services'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Includes all cookbooks not in init for testing purposes'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
supports 'centos'
depends 'fb_apache'
depends 'fb_apt_cacher'
depends 'fb_reprepro'
depends 'fb_zfs'
