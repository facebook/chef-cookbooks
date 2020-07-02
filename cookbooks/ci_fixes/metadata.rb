# Copyright (c) 2018-present, Facebook, Inc.
name 'ci_fixes'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Misc fixes to make the CI work'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'ubuntu'
depends 'fb_helpers'
