# Copyright (c) 2018-present, Facebook, Inc.
name 'fb_syslog'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures syslog'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
supports 'centos'
supports 'mac_os_x'
depends 'fb_helpers'
depends 'fb_systemd'
