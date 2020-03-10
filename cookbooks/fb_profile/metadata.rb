# Copyright (c) 2020-present, Vicarious, Inc.
# Copyright (c) 2020-present, Facebook, Inc.
name 'fb_profile'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
source_url 'https://github.com/facebook/chef-cookbooks/'
description 'Installs/Configures /etc/profile.d'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# never EVER change this number, ever.
version '0.1.0'
supports 'centos'
supports 'debian'
supports 'mac_os_x'
supports 'ubuntu'
depends 'fb_helpers'
