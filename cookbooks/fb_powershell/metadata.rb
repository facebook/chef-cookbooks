# Copyright (c) 2020-present, Facebook, Inc.
name 'fb_powershell'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures PowerShell'
source_url 'https://github.com/facebook/chef-cookbooks/'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# never EVER change this number, ever.
version '0.1.0'
supports 'mac_os_x'
supports 'redhat'
supports 'windows'
depends 'fb_helpers'
