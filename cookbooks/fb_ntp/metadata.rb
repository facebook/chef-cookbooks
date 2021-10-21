# Copyright (c) 2012-present, Facebook, Inc.
name 'fb_ntp'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
source_url 'https://github.com/facebook/chef-cookbooks/'
license 'Apache-2.0'
description 'Installs/Configures NTP'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
supports 'centos'
depends 'fb_systemd'
depends 'fb_helpers'
