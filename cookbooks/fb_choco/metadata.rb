# Copyright (c) 2020-present, Facebook, Inc.
name 'fb_choco'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
source_url 'https://github.com/facebook/chef-cookbooks/'
license 'Apache-2.0'
description 'Configures Chocolatey for Windows clients'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.1'
supports 'windows'
depends 'fb_helpers'
