# Copyright (c) 2012-present, Facebook, Inc.
name 'fb_network_scripts'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures networking'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
depends 'fb_ethers'
depends 'fb_helpers'
depends 'fb_sysctl'
