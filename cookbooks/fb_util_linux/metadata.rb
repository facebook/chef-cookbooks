# Copyright (c) 2018-present, Facebook, Inc.
name 'fb_util_linux'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures fb_util_linux'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# never EVER change this number, ever.
version '0.1.0'
supports 'centos'
depends 'fb_helpers'
depends 'fb_systemd'
