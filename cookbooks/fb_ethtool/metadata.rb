# Copyright (c) 2014-present, Facebook, Inc.
name 'fb_ethtool'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures fb_ethtool'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'ubuntu'
depends 'fb_helpers'
