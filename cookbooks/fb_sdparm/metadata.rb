# Copyright (c) 2012-present, Facebook, Inc.
name 'fb_sdparm'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures sdparm'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'centos'
depends 'fb_helpers'
depends 'fb_sysfs'
depends 'fb_fstab'
